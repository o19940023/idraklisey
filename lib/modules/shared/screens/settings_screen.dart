import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../providers/app_state.dart';
import '../../../core/utils/navigation_utils.dart';
import '../../../data/models/student_model.dart';
import '../../admin/widgets/reorderable_module_grid.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();

  /// Supported languages shown in the picker.
  static const languages = [
    ('az', '🇦🇿', 'Azərbaycan dili'),
    ('en', '🇬🇧', 'English'),
    ('ru', '🇷🇺', 'Русский'),
  ];
}

class _SettingsScreenState extends State<SettingsScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _packageInfo = info);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDarkMode = appState.isDarkMode;

    // Get user info - support all user types
    final currentUser = appState.currentUser;
    final studentUser = appState.student;

    // Determine which user data to display
    String displayName = 'İstifadəçi';
    String displayEmail = '';
    String? displayPhotoUrl;
    String? displayClass;

    if (currentUser != null) {
      // Admin, Teacher, Parent
      displayName = currentUser.fullName ?? 'İstifadəçi';
      displayEmail = currentUser.email ?? '';
      displayPhotoUrl = currentUser.photoUrl;
      // Teachers have className, others might not
      if (currentUser.className?.isNotEmpty == true) {
        displayClass = currentUser.className;
      }
    } else if (studentUser != null) {
      // Student
      displayName = studentUser.fullName;
      displayEmail = studentUser.email ?? '';
      displayPhotoUrl = studentUser.photoUrl;
      displayClass = studentUser.className;
    }
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(loc.settings),
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppShadows.md,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white.withAlpha(30),
                    backgroundImage: displayPhotoUrl?.isNotEmpty == true
                        ? NetworkImage(displayPhotoUrl!)
                        : null,
                    child: displayPhotoUrl?.isEmpty != false
                        ? Icon(
                            Icons.person,
                            size: 32,
                            color: Colors.white.withAlpha(180),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayEmail,
                          style: TextStyle(
                            color: Colors.white.withAlpha(200),
                            fontSize: 12,
                          ),
                        ),
                        if (displayClass?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.white.withAlpha(40),
                              ),
                            ),
                            child: Text(
                              displayClass!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Settings Sections
            _buildSectionTitle(loc.appearance),
            _buildSettingCard(
              icon: Icons.dark_mode_rounded,
              title: loc.darkMode,
              subtitle: isDarkMode ? loc.darkModeActive : loc.lightModeActive,
              trailing: Switch.adaptive(
                value: isDarkMode,
                onChanged: (val) => appState.toggleTheme(),
                activeColor: AppColors.primaryAccent,
              ),
            ),

            _buildSectionTitle(loc.customization),
            _buildSettingCard(
              icon: Icons.language_rounded,
              title: loc.language,
              subtitle: _currentLanguageLabel(appState),
              onTap: () => _showLanguagePicker(context, appState),
            ),
            _buildSettingCard(
              icon: Icons.dashboard_customize_rounded,
              title: loc.customizeModules,
              subtitle: loc.customizeModulesDesc,
              onTap: () {
                // Get current user modules from AppState
                final currentModules =
                    appState.userPreferences?.dashboardModules ?? [];
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReorderableModuleGrid(
                      modules: currentModules,
                      onReorder: (reorderedModules) {
                        // Update module order in AppState
                        appState.updateModuleOrder(reorderedModules);
                        Navigator.pop(context);
                      },
                      isReorderMode: true,
                    ),
                  ),
                );
              },
            ),

            _buildSectionTitle(loc.notifications),
            _buildSettingCard(
              icon: Icons.notifications_active_rounded,
              title: loc.pushNotifications,
              subtitle: loc.pushNotificationsDesc,
              trailing: Switch.adaptive(
                value: true, // TODO: Add notification settings to AppState
                onChanged: (val) {
                  // TODO: Implement notification toggle
                },
                activeColor: AppColors.success,
              ),
            ),

            _buildSectionTitle(loc.account),
            _buildSettingCard(
              icon: Icons.lock_outline_rounded,
              title: loc.changePassword,
              subtitle: loc.changePasswordDesc,
              onTap: () => _showChangePasswordDialog(context, appState, loc),
            ),
            _buildSettingCard(
              icon: Icons.logout_rounded,
              title: loc.logout,
              subtitle: loc.logoutDevice,
              iconColor: AppColors.danger,
              onTap: () => _showLogoutDialog(context, appState),
            ),

            _buildSectionTitle(loc.info),
            _buildSettingCard(
              icon: Icons.help_outline_rounded,
              title: loc.helpCenter,
              subtitle: loc.faqDesc,
              onTap: () {
                // TODO: Navigate to help screen
              },
            ),
            _buildSettingCard(
              icon: Icons.privacy_tip_outlined,
              title: loc.privacyPolicy,
              subtitle: loc.privacyDesc,
              onTap: () {
                // TODO: Navigate to privacy policy
              },
            ),
            _buildSettingCard(
              icon: Icons.description_outlined,
              title: loc.termsOfService,
              subtitle: loc.termsDesc,
              onTap: () {
                // TODO: Navigate to terms of service
              },
            ),

            // App Build Info
            const SizedBox(height: 24),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/logo.png',
                    height: 48,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.school_rounded,
                        size: 48,
                        color: AppColors.primaryAccent,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    loc.appName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    loc.digitalEducationPlatform,
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: AppColors.cardBorder, height: 1),
                  const SizedBox(height: 16),
                  _buildInfoRow(loc.version, _packageInfo?.version ?? '1.4.8'),
                  _buildInfoRow(loc.build, _packageInfo?.buildNumber ?? '38'),
                  _buildInfoRow(
                    loc.packageName,
                    _packageInfo?.packageName ?? 'az.idrak.liseyi',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    loc.copyright,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _currentLanguageLabel(AppState appState) {
    final code = appState.locale?.languageCode;
    for (final (langCode, _, name) in SettingsScreen.languages) {
      if (langCode == code) return name;
    }
    return 'Sistem';
  }

  void _showLanguagePicker(BuildContext context, AppState appState) {
    final loc = AppLocalizations.of(context);
    final current = appState.locale?.languageCode;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(
              loc.selectLanguage,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            // System default option
            ListTile(
              leading: const Icon(
                Icons.language_rounded,
                color: AppColors.primaryAccent,
              ),
              title: Text(
                loc.systemDefault,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              trailing: current == null
                  ? const Icon(
                      Icons.check_rounded,
                      color: AppColors.primaryAccent,
                    )
                  : null,
              onTap: () => Navigator.pop(ctx, '__system__'),
            ),
            for (final (code, flag, name) in SettingsScreen.languages)
              ListTile(
                leading: Text(flag, style: const TextStyle(fontSize: 22)),
                title: Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                trailing: current == code
                    ? const Icon(
                        Icons.check_rounded,
                        color: AppColors.primaryAccent,
                      )
                    : null,
                onTap: () => Navigator.pop(ctx, code),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ).then((result) {
      if (result == null || !mounted) return;
      appState.setLocale(result == '__system__' ? null : result as String?);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.languageChanged)));
    });
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: AppColors.primaryAccent,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.primaryAccent).withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: iconColor ?? AppColors.primaryAccent,
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
        ),
        trailing:
            trailing ??
            (onTap != null
                ? Icon(Icons.chevron_right_rounded, color: AppColors.textMuted)
                : null),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(
    BuildContext context,
    AppState appState,
    AppLocalizations loc,
  ) {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isLoading = false;
    String? errorMessage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: AppShadows.md,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.cardBorder,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccent.withAlpha(20),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.lock_reset_rounded,
                              color: AppColors.primaryAccent,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.changePassword,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  loc.changePasswordDesc,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.danger.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.danger.withAlpha(80)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  errorMessage!,
                                  style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Old Password
                      Text(
                        'Cari Şifrə',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: oldPassCtrl,
                        obscureText: obscureOld,
                        decoration: InputDecoration(
                          hintText: 'Mövcud şifrənizi daxil edin',
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(obscureOld ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                            onPressed: () => setModalState(() => obscureOld = !obscureOld),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Cari şifrə tələb olunur' : null,
                      ),
                      const SizedBox(height: 14),

                      // New Password
                      Text(
                        'Yeni Şifrə',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: newPassCtrl,
                        obscureText: obscureNew,
                        decoration: InputDecoration(
                          hintText: 'Ən azı 4 simvol',
                          prefixIcon: const Icon(Icons.key_rounded, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                            onPressed: () => setModalState(() => obscureNew = !obscureNew),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Yeni şifrə daxil edin';
                          if (v.trim().length < 4) return 'Şifrə ən azı 4 simvol olmalıdır';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Confirm New Password
                      Text(
                        'Yeni Şifrənin Təkrarı',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: confirmPassCtrl,
                        obscureText: obscureConfirm,
                        decoration: InputDecoration(
                          hintText: 'Yeni şifrəni təkrar daxil edin',
                          prefixIcon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                            onPressed: () => setModalState(() => obscureConfirm = !obscureConfirm),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Şifrə təkrarını daxil edin';
                          if (v.trim() != newPassCtrl.text.trim()) return 'Şifrələr uyğun gəlmir';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          onPressed: isLoading
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setModalState(() {
                                    isLoading = true;
                                    errorMessage = null;
                                  });

                                  final success = await appState.changeCurrentUserPassword(
                                    oldPassword: oldPassCtrl.text.trim(),
                                    newPassword: newPassCtrl.text.trim(),
                                  );

                                  if (context.mounted) {
                                    if (success) {
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('✓ Şifrəniz uğurla dəyişdirildi!'),
                                          backgroundColor: AppColors.success,
                                          duration: Duration(seconds: 3),
                                        ),
                                      );
                                    } else {
                                      setModalState(() {
                                        isLoading = false;
                                        errorMessage = 'Cari şifrəniz yanlışdır. Yenidən cəhd edin.';
                                      });
                                    }
                                  }
                                },
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  'Şifrəni Yenilə',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Çıxış',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Hesabdan çıxmaq istədiyinizə əminsiniz?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Ləğv et', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              appState.logout();
            },
            child: const Text('Bəli, Çıxış', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
