import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/utils/navigation_utils.dart';
import '../../../core/widgets/responsive.dart';
import '../../../data/models/menu_model.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/app_state.dart';

class CafeteriaMenuScreen extends StatefulWidget {
  const CafeteriaMenuScreen({super.key});

  @override
  State<CafeteriaMenuScreen> createState() => _CafeteriaMenuScreenState();
}

class _CafeteriaMenuScreenState extends State<CafeteriaMenuScreen> {
  int _selectedDayIndex = 0;
  int _currentOffset = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMenu(0);
    });
  }

  void _loadMenu(int offset) {
    setState(() {
      _currentOffset = offset;
      _selectedDayIndex = 0;
    });
    context.read<AppState>().fetchCanteenWeeklyMenu(offset: offset);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final palette = AppPalette.of(context);
    final appState = context.watch<AppState>();
    final weeklyMenu = appState.canteenWeeklyMenu;
    final isLoading = appState.isCanteenMenuLoading;

    final days = weeklyMenu?.days ?? [];
    final hasMenu = weeklyMenu != null && weeklyMenu.found && days.isNotEmpty;

    // Clamp selected day index
    final activeDayIndex = (_selectedDayIndex < days.length) ? _selectedDayIndex : 0;
    final activeDay = hasMenu ? days[activeDayIndex] : null;

    final weekRangeLabel = weeklyMenu?.weekLabel.isNotEmpty == true
        ? weeklyMenu!.weekLabel
        : (_currentOffset == 0 ? 'Cari Həftə' : 'Həftə ${_currentOffset > 0 ? "+$_currentOffset" : _currentOffset}');

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: palette.bgBase,
        body: RefreshIndicator(
          onRefresh: () async {
            await context.read<AppState>().fetchCanteenWeeklyMenu(offset: _currentOffset);
          },
          color: const Color(0xFFD97706),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // ── 1. App Bar with Hero Artwork ──
              _buildAppBar(context, loc, weekRangeLabel),

              SliverToBoxAdapter(
                child: ResponsiveCenter(
                  horizontalPadding: 0,
                  child: Padding(
                    padding: responsivePadding(context).copyWith(top: 14, bottom: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── 2. Week Navigator ──
                        _buildWeekNavigator(context, weeklyMenu, isLoading),
                        const SizedBox(height: 14),

                        if (isLoading)
                          _buildLoadingSkeleton()
                        else if (!hasMenu)
                          _buildEmptyStateCard(context, weeklyMenu)
                        else ...[
                          // ── 3. Day Selector Tabs ──
                          _buildDaySelectorRibbon(context, days, activeDayIndex),
                          const SizedBox(height: 14),

                          // ── 4. Daily Menu Details ──
                          if (activeDay != null)
                            _buildDailyMenuContent(context, activeDay),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 1. APP BAR ──
  SliverAppBar _buildAppBar(BuildContext context, AppLocalizations loc, String weekLabel) {
    return SliverAppBar(
      expandedHeight: 148,
      pinned: true,
      elevation: 0,
      backgroundColor: const Color(0xFF1C1917),
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 15,
            color: Colors.white,
          ),
        ),
        onPressed: () => handleBackNavigation(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF8B1A1A), // Liseyin rəsmi mətbəx/yeməkxana bordosu
                Color(0xFFB71C1C),
                Color(0xFFD97706), // Qızılı kulinariya çaları
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  Icons.restaurant_menu_rounded,
                  size: 140,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.restaurant_rounded,
                              size: 22,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  loc.cafeteriaMenu,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Sağlam qidalanma və gündəlik təzə menyu',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
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
    );
  }

  // ── 2. WEEK NAVIGATOR ──
  Widget _buildWeekNavigator(BuildContext context, CanteenWeeklyMenu? menu, bool isLoading) {
    final palette = AppPalette.of(context);
    final weekText = menu?.weekLabel.isNotEmpty == true ? menu!.weekLabel : 'Tarix aralığı';
    final isCurrent = _currentOffset == 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.borderHairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Week Button
          InkWell(
            onTap: isLoading ? null : () => _loadMenu(_currentOffset - 1),
            borderRadius: BorderRadius.circular(9),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: palette.surface2,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chevron_left_rounded, size: 16, color: palette.textPrimary),
                  const SizedBox(width: 2),
                  Text(
                    'Əvvəlki',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: palette.textPrimary),
                  ),
                ],
              ),
            ),
          ),

          // Center Week Indicator
          InkWell(
            onTap: isCurrent ? null : () => _loadMenu(0),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_month_rounded, size: 13, color: const Color(0xFFD97706)),
                      const SizedBox(width: 5),
                      Text(
                        weekText,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    isCurrent ? 'Cari Həftə' : 'Bu həftəyə qayıt',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w800,
                      color: isCurrent ? palette.textTertiary : const Color(0xFFD97706),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Next Week Button
          InkWell(
            onTap: isLoading ? null : () => _loadMenu(_currentOffset + 1),
            borderRadius: BorderRadius.circular(9),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: palette.surface2,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Növbəti',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: palette.textPrimary),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, size: 16, color: palette.textPrimary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. DAY SELECTOR RIBBON ──
  Widget _buildDaySelectorRibbon(BuildContext context, List<CanteenDayMenu> days, int selectedIndex) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(days.length, (index) {
          final day = days[index];
          final isSelected = index == selectedIndex;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedDayIndex = index),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFB71C1C) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFB71C1C) : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFB71C1C).withValues(alpha: 0.28),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      day.dayName,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF1E293B),
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      day.dateLabel,
                      style: TextStyle(
                        color: isSelected ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF64748B),
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
    );
  }

  // ── 4. DAILY MENU CONTENT ──
  Widget _buildDailyMenuContent(BuildContext context, CanteenDayMenu day) {
    final palette = AppPalette.of(context);
    final meals = day.meals;

    final mealConfigs = [
      {
        'key': 'breakfast',
        'title': 'Səhər Yeməyi',
        'badge': 'Səhər',
        'icon': Icons.wb_sunny_rounded,
        'color': const Color(0xFFD97706),
        'bg': const Color(0xFFFEF3C7),
      },
      {
        'key': 'lunch',
        'title': 'Nahar Yeməyi',
        'badge': 'Nahar',
        'icon': Icons.lunch_dining_rounded,
        'color': const Color(0xFFB71C1C),
        'bg': const Color(0xFFFEE2E2),
      },
      {
        'key': 'snack',
        'title': 'Qəlyanaltı',
        'badge': 'Qəlyanaltı',
        'icon': Icons.cookie_rounded,
        'color': const Color(0xFF059669),
        'bg': const Color(0xFFD1FAE5),
      },
      {
        'key': 'dinner',
        'title': 'Axşam Yeməyi',
        'badge': 'Axşam',
        'icon': Icons.dinner_dining_rounded,
        'color': const Color(0xFF4338CA),
        'bg': const Color(0xFFE0E7FF),
      },
    ];

    bool hasAnyMeal = false;
    for (final cfg in mealConfigs) {
      final items = meals[cfg['key'] as String];
      if (items != null && items.isNotEmpty) {
        hasAnyMeal = true;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day Banner with official approval check
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.borderHairline),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Color(0xFF137333),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${day.dayName} • ${day.dateLabel}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4EA),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Təsdiqlənib',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF137333),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (!hasAnyMeal)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.borderHairline),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.restaurant_rounded, size: 36, color: palette.textTertiary),
                  const SizedBox(height: 8),
                  Text(
                    'Bu gün üçün menyu daxil edilməyib.',
                    style: TextStyle(fontSize: 13, color: palette.textSecondary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          )
        else
          ...mealConfigs.map((cfg) {
            final key = cfg['key'] as String;
            final items = meals[key];
            if (items == null || items.isEmpty) return const SizedBox.shrink();

            final color = cfg['color'] as Color;
            final bg = cfg['bg'] as Color;
            final icon = cfg['icon'] as IconData;
            final title = cfg['title'] as String;
            final badge = cfg['badge'] as String;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: palette.borderHairline),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Meal Header Ribbon
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: bg.withValues(alpha: 0.45),
                        border: Border(bottom: BorderSide(color: color.withValues(alpha: 0.15))),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(icon, size: 14, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                                color: color,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Meal Items List
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: items.map((dish) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 5),
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    dish,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  // ── 5. OFFICIAL EMPTY STATE (Mirrors Web Exactly) ──
  Widget _buildEmptyStateCard(BuildContext context, CanteenWeeklyMenu? menu) {
    final palette = AppPalette.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 38),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.borderHairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD97706).withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.restaurant_menu_rounded,
                size: 36,
                color: Color(0xFFD97706),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Cari həftə üçün menyu əlavə edilməyib',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E293B),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Menyu məsul şəxs (anbar / tibb məntəqəsi / rəhbərlik) tərəfindən portala daxil edilib təsdiqləndikdən sonra burada avtomatik əks olunacaqdır.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          // Button to view previous approved week
          if (_currentOffset == 0)
            ElevatedButton.icon(
              onPressed: () => _loadMenu(-1),
              icon: const Icon(Icons.history_rounded, size: 16, color: Colors.white),
              label: const Text(
                'Əvvəlki həftənin menyusuna bax',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C),
                elevation: 1,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ── SKELETON LOADER ──
  Widget _buildLoadingSkeleton() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: const Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: Color(0xFFD97706), strokeWidth: 2.5),
            SizedBox(height: 14),
            Text(
              'Həftəlik menyu yüklənir...',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
