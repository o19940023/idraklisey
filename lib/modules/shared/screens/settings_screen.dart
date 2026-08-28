// Ayarlar Ekranı - Tüm paneller için ortak
// Modül ve navigation sıralamasını sıfırlama, tema, bildirimler vb.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../providers/app_state.dart';
import '../../../core/utils/navigation_utils.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currentUser = appState.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Tənzimləmələr',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => handleBackNavigation(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Kullanıcı Bilgileri
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: AppShadows.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withAlpha(20),
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: Icon(
                    currentUser?.role.icon ?? Icons.person_rounded,
                    color: AppColors.primary,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser?.fullName ?? 'İstifadəçi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentUser?.role.displayName ?? '',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        currentUser?.email ?? currentUser?.idrakCode ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Görünüm Ayarları
          _buildSectionTitle('Görünüm'),
          const SizedBox(height: 12),

          _buildSettingTile(
            context: context,
            icon: appState.isDarkMode
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
            iconColor: AppColors.gold,
            title: 'Tema',
            subtitle: appState.isDarkMode ? 'Tünd rejim' : 'Açıq rejim',
            trailing: Switch(
              value: appState.isDarkMode,
              onChanged: (_) => appState.toggleTheme(),
              activeThumbColor: AppColors.primary,
            ),
            onTap: () => appState.toggleTheme(),
          ),

          const SizedBox(height: 24),

          // Özelleştirme Ayarları
          _buildSectionTitle('Özelleştirmə'),
          const SizedBox(height: 12),

          _buildSettingTile(
            context: context,
            icon: Icons.dashboard_customize_rounded,
            iconColor: AppColors.primaryAccent,
            title: 'Modül Sıralamasını Sıfırla',
            subtitle: 'Dashboard modüllərini varsayılan sıraya qaytarın',
            trailing: const Icon(
              Icons.restart_alt_rounded,
              color: AppColors.danger,
            ),
            onTap: () => _showResetModulesDialog(context, appState),
          ),

          _buildSettingTile(
            context: context,
            icon: Icons.navigation_rounded,
            iconColor: const Color(0xFF7C3AED),
            title: 'Navigation Sıralamasını Sıfırla',
            subtitle: 'Alt menyu sırasını varsayılana qaytarın',
            trailing: const Icon(
              Icons.restart_alt_rounded,
              color: AppColors.danger,
            ),
            onTap: () => _showResetNavigationDialog(context, appState),
          ),

          _buildSettingTile(
            context: context,
            icon: Icons.restore_rounded,
            iconColor: AppColors.danger,
            title: 'Bütün Tənzimləmələri Sıfırla',
            subtitle: 'Modül və navigation sıralamalarını sıfırla',
            trailing: const Icon(
              Icons.warning_rounded,
              color: AppColors.danger,
            ),
            onTap: () => _showResetAllDialog(context, appState),
          ),

          const SizedBox(height: 24),

          // Hesap Ayarları
          _buildSectionTitle('Hesab'),
          const SizedBox(height: 12),

          _buildSettingTile(
            context: context,
            icon: Icons.logout_rounded,
            iconColor: AppColors.danger,
            title: 'Hesabdan Çıxış',
            subtitle: 'Sistemdən təhlükəsiz çıxış edin',
            onTap: () => _showLogoutDialog(context, appState),
          ),

          const SizedBox(height: 40),

          // Versiyon Bilgisi
          Center(
            child: Column(
              children: [
                Text(
                  'İdrak Liseyi',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Versiyon 2.0.0 • 2025',
                  style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppShadows.sm,
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withAlpha(20),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              )
            : null,
        trailing:
            trailing ??
            Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
      ),
    );
  }

  void _showResetModulesDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.dashboard_customize_rounded,
                color: AppColors.primaryAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Modül Sıralaması',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: const Text(
          'Dashboard modüllərinin sırasını varsayılan vəziyyətə qaytarmaq istədiyinizə əminsiniz? Bu əməliyyat geri alına bilməz.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Ləğv et',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);

              // Sadece modülleri sıfırla
              await appState.resetUserPreferences();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ Modül sıralaması sıfırlandı'),
                    backgroundColor: AppColors.success,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
  }

  void _showResetNavigationDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.navigation_rounded,
                color: Color(0xFF7C3AED),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Navigation Sıralaması',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: const Text(
          'Alt menyu elementlərinin sırasını varsayılan vəziyyətə qaytarmaq istədiyinizə əminsiniz? Bu əməliyyat geri alına bilməz.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Ləğv et',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);

              await appState.resetUserPreferences();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ Navigation sıralaması sıfırlandı'),
                    backgroundColor: AppColors.success,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
  }

  void _showResetAllDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.restore_rounded,
                color: AppColors.danger,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Bütün Tənzimləmələr',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: const Text(
          'BÜTÜN tənzimləmələri (modül və navigation sıralamaları) varsayılana qaytarmaq istədiyinizə əminsiniz? Bu əməliyyat geri alına bilməz.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Ləğv et',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);

              await appState.resetUserPreferences();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ Bütün tənzimləmələr sıfırlandı'),
                    backgroundColor: AppColors.success,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
            child: const Text('Hamısını Sıfırla'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.danger,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Hesabdan Çıxış',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: const Text(
          'Hesabdan çıxmaq istədiyinizə əminsiniz?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Ləğv et',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              appState.logout();
            },
            child: const Text('Çıxış Et'),
          ),
        ],
      ),
    );
  }
}
