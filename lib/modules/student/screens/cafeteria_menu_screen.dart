import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/utils/navigation_utils.dart';
import '../../../providers/app_state.dart';
import '../../../data/models/menu_model.dart';
import '../../../l10n/app_localizations.dart';

class CafeteriaMenuScreen extends StatefulWidget {
  const CafeteriaMenuScreen({super.key});

  @override
  State<CafeteriaMenuScreen> createState() => _CafeteriaMenuScreenState();
}

class _CafeteriaMenuScreenState extends State<CafeteriaMenuScreen> {
  int _selectedDayIndex = 0;
  DateTime? _selectedWeekStart; // null = cari həftə

  static const List<String> _weekdayNames = [
    'Bazar ertəsi',
    'Çərşənbə axşamı',
    'Çərşənbə',
    'Cümə axşamı',
    'Cümə',
    'Şənbə',
    'Bazar',
  ];

  static const List<String> _weekdayShortNames = [
    'B.E',
    'Ç.A',
    'Çər',
    'C.A',
    'Cüm',
    'Şən',
    'Baz',
  ];

  /// Həftənin başlanğıcı (Bazar ertəsi, saat 00:00)
  DateTime _weekStart(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';

  String _weekdayName(int weekday) => _weekdayNames[weekday - 1];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final appState = Provider.of<AppState>(context);
    final allMenus = appState.weeklyMenu;

    // Seçilmiş həftənin günləri (Bazar ertəsi — Bazar)
    final thisWeekStart = _weekStart(DateTime.now());
    final weekStart = _selectedWeekStart ?? thisWeekStart;
    final weekEnd = weekStart.add(const Duration(days: 7));
    final weekMenus =
        allMenus
            .where(
              (m) => !m.date.isBefore(weekStart) && m.date.isBefore(weekEnd),
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    final dayIndex = _selectedDayIndex < weekMenus.length
        ? _selectedDayIndex
        : 0;
    final currentMenu = weekMenus.isNotEmpty ? weekMenus[dayIndex] : null;

    // Həftə nişanları
    final weekChipStarts = <DateTime>{
      thisWeekStart,
      thisWeekStart.add(const Duration(days: 7)),
    };
    for (final m in allMenus) {
      final ws = _weekStart(m.date);
      if (!ws.isBefore(thisWeekStart)) weekChipStarts.add(ws);
    }
    final weekChips = weekChipStarts.toList()..sort();

    final currentUser = appState.currentUser;
    final canManageMenu =
        currentUser?.role == UserRole.admin ||
        (currentUser?.role == UserRole.teacher &&
            (currentUser?.teacherPermissions?.canManageCafeteria ?? false));

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: canManageMenu
          ? FloatingActionButton.extended(
              onPressed: () => _showAddMenuItemDialog(
                context,
                appState,
                currentMenu?.date ?? weekStart,
              ),
              backgroundColor: const Color(0xFFD97706),
              elevation: 4,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Menyuya Əlavə Et',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            )
          : null,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Premium Gourmet Amber Gradient Header ──
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF1C1917),
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
              ),
              onPressed: () => handleBackNavigation(context),
            ),
            actions: [
              if (canManageMenu)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706).withAlpha(180),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.restaurant_rounded, size: 18, color: Colors.white),
                    ),
                    tooltip: 'Yemək Əlavə Et',
                    onPressed: () => _showAddMenuItemDialog(
                      context,
                      appState,
                      currentMenu?.date ?? weekStart,
                    ),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1C1917), Color(0xFF78350F), Color(0xFFD97706)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -15,
                      bottom: -15,
                      child: Icon(Icons.restaurant_menu_rounded, size: 135, color: Colors.white.withAlpha(12)),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 44, 20, 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(25),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.lunch_dining_rounded, size: 22, color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loc.cafeteriaMenu,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Sağlam qidalanma və gündəlik təzə menyu',
                                      style: TextStyle(
                                        color: Colors.white.withAlpha(180),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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

          // ── Content Sliver Body ──
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Permission Banner
                if (canManageMenu)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: const Color(0xFFD97706).withAlpha(15),
                    child: Row(
                      children: [
                        const Icon(Icons.admin_panel_settings_outlined, size: 16, color: Color(0xFFD97706)),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'İdarəetmə aktivdir: Menyunu dəyişə və yeməkləri redaktə edə bilərsiniz.',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Week Switcher
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: weekChips
                          .map((ws) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _buildWeekChip(ws, thisWeekStart),
                              ))
                          .toList(),
                    ),
                  ),
                ),

                // Day Selector Ribbon
                if (weekMenus.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: List.generate(weekMenus.length, (index) {
                          final isSelected = index == dayIndex;
                          final menu = weekMenus[index];
                          final shortDay = _weekdayShortNames[menu.date.weekday - 1];

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () => setState(() => _selectedDayIndex = index),
                              borderRadius: BorderRadius.circular(14),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFD97706) : AppColors.background,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFFD97706) : AppColors.cardBorder,
                                    width: isSelected ? 1.4 : 1,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFFD97706).withAlpha(60),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      shortDay,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : AppColors.textPrimary,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _fmtDate(menu.date),
                                      style: TextStyle(
                                        color: isSelected ? Colors.white.withAlpha(200) : AppColors.textMuted,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),

                // Main Daily Focus Card & Dishes
                if (currentMenu != null) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFB45309), Color(0xFFD97706)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD97706).withAlpha(50),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentMenu.dayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withAlpha(30),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      currentMenu.mealTime,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${currentMenu.items.length} növ təam',
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(220),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: AppShadows.sm,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Ümumi Kalori',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Row(
                                  children: [
                                    const Icon(Icons.local_fire_department_rounded, color: Color(0xFFD97706), size: 16),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${currentMenu.totalCalories} kkal',
                                      style: const TextStyle(
                                        color: Color(0xFFD97706),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Hygiene & Diet Ribbon
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDietBadge(Icons.eco_rounded, 'Təbii Ərzaqlar', const Color(0xFF10B981)),
                          _buildDietBadge(Icons.verified_rounded, 'Keyfiyyət Nəzarəti', const Color(0xFF2563EB)),
                          _buildDietBadge(Icons.health_and_safety_rounded, 'Sanitar Təsdiq', const Color(0xFF8B5CF6)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Food Items List
                  if (currentMenu.items.isEmpty)
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.restaurant_menu_outlined, size: 40, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Bu gün üçün menyu daxil edilməyib.',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Təqvimdəki digər günlərə keçid edə bilərsiniz.',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                            if (canManageMenu) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD97706),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                ),
                                onPressed: () => _showAddMenuItemDialog(context, appState, currentMenu.date),
                                icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                                label: const Text(
                                  'İlk Yeməyi Əlavə Et',
                                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Column(
                        children: currentMenu.items
                            .asMap()
                            .entries
                            .map((entry) => _buildMenuItemCard(
                                  context,
                                  appState,
                                  entry.value,
                                  entry.key,
                                  canManageMenu,
                                  currentMenu.date,
                                ))
                            .toList(),
                      ),
                    ),
                ] else ...[
                  // No menu for this whole week
                  Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(36),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 44, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            'Bu həftə üçün menyu tərtib edilməyib.',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 90),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDietBadge(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildMenuItemCard(
    BuildContext context,
    AppState appState,
    MenuItem item,
    int itemIndex,
    bool canManage,
    DateTime menuDate,
  ) {
    // Başlıq item-i üçün fərqli dizayn
    if (item.category == 'Başlıq') {
      return Container(
        margin: const EdgeInsets.only(top: 14, bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFD97706).withAlpha(15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFD97706).withAlpha(40)),
        ),
        child: Row(
          children: [
            const Icon(Icons.restaurant_rounded, size: 16, color: Color(0xFFD97706)),
            const SizedBox(width: 8),
            Text(
              item.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFFB45309),
                letterSpacing: 0.3,
              ),
            ),
            const Spacer(),
            Container(
              height: 2,
              width: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFD97706), Colors.transparent],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Normal yemək item-i
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              item.imageUrl,
              width: 76,
              height: 76,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.restaurant_rounded,
                  color: AppColors.textMuted,
                  size: 28,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706).withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.category,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${item.calories} kkal • ${item.weightGram}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (canManage) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.delete_outline_rounded, size: 17, color: AppColors.danger),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (dCtx) {
                                  final dLoc = AppLocalizations.of(dCtx);
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                                    title: Text(dLoc.delete),
                                    content: Text('"${item.name}" menyudan silinsin?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dCtx),
                                        child: Text(dLoc.cancel),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.danger,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        onPressed: () {
                                          appState.removeMenuItemFromDay(menuDate, itemIndex);
                                          Navigator.pop(dCtx);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(dLoc.successfullyDeleted),
                                              backgroundColor: AppColors.danger,
                                            ),
                                          );
                                        },
                                        child: Text(dLoc.delete, style: const TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                if (item.allergens.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 5,
                    runSpacing: 4,
                    children: item.allergens.map((allergen) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withAlpha(12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.danger.withAlpha(35)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 10, color: AppColors.danger),
                            const SizedBox(width: 3),
                            Text(
                              allergen,
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: AppColors.danger,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekChip(DateTime start, DateTime thisWeekStart) {
    final loc = AppLocalizations.of(context);
    final end = start.add(const Duration(days: 6));
    final isSelected = (_selectedWeekStart ?? thisWeekStart) == start;
    final offsetDays = start.difference(thisWeekStart).inDays;
    final title = offsetDays == 0
        ? loc.thisWeek
        : offsetDays == 7
            ? 'Növbəti həftə'
            : '${_fmtDate(start)} – ${_fmtDate(end)}';

    return InkWell(
      onTap: () => setState(() {
        _selectedWeekStart = start;
        _selectedDayIndex = 0;
      }),
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD97706) : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFD97706) : AppColors.cardBorder,
            width: isSelected ? 1.4 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFD97706).withAlpha(60),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 2),
            if (offsetDays <= 7)
              Text(
                '${_fmtDate(start)} – ${_fmtDate(end)}',
                style: TextStyle(
                  color: isSelected ? Colors.white.withAlpha(200) : AppColors.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddMenuItemDialog(
    BuildContext context,
    AppState appState,
    DateTime menuDate,
  ) {
    final nameCtrl = TextEditingController();
    final calCtrl = TextEditingController(text: '300');
    final weightCtrl = TextEditingController(text: '200g');
    final allergenCtrl = TextEditingController();
    DateTime selectedDate = DateTime(menuDate.year, menuDate.month, menuDate.day);
    String category = 'Əsas Yemək';
    final categories = ['Şorba', 'Əsas Yemək', 'Qarnir', 'Salat', 'Şirniyyat / İçki'];

    showDialog(
      context: context,
      builder: (ctx) {
        final dLoc = AppLocalizations.of(ctx);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFFD97706), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text('Yeni Yemək Əlavə Et', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Date picker
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          helpText: 'Yeməyin tarixini seçin',
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = DateTime(picked.year, picked.month, picked.day));
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFD97706).withAlpha(50)),
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFFD97706).withAlpha(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, color: Color(0xFFD97706), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${_weekdayName(selectedDate.weekday)}, ${_fmtDate(selectedDate)}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                              ),
                            ),
                            const Icon(Icons.edit_calendar_outlined, size: 16, color: Color(0xFFD97706)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Yeməyin Adı *',
                        prefixIcon: const Icon(Icons.restaurant_rounded, color: Color(0xFFD97706), size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: InputDecoration(
                        labelText: 'Kateqoriya',
                        prefixIcon: const Icon(Icons.category_rounded, color: Color(0xFFD97706), size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => category = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: calCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: '${dLoc.calories} (kkal) *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: weightCtrl,
                            decoration: InputDecoration(
                              labelText: 'Porsiya *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: allergenCtrl,
                      decoration: InputDecoration(
                        labelText: '${dLoc.allergens} (vergüllə)',
                        hintText: 'Məs: Qlüten, Süd, Qoz',
                        prefixIcon: const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(dLoc.cancel),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Yeməyin adını qeyd edin!')),
                      );
                      return;
                    }
                    final allergens = allergenCtrl.text
                        .split(',')
                        .map((a) => a.trim())
                        .where((a) => a.isNotEmpty)
                        .toList();

                    final newItem = MenuItem(
                      name: nameCtrl.text.trim(),
                      category: category,
                      calories: int.tryParse(calCtrl.text.trim()) ?? 250,
                      weightGram: weightCtrl.text.trim().isNotEmpty ? weightCtrl.text.trim() : '200g',
                      allergens: allergens,
                      imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
                    );

                    appState.addMenuItemToDay(selectedDate, newItem);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"${newItem.name}" menyuya əlavə edildi!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  child: Text(dLoc.add, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
