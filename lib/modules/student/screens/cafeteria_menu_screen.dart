import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/widgets/status_badge.dart';
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

    // Həftə nişanları: bu həftə + növbəti həftə + menyusu olan bütün gələcək həftələr
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
      appBar: AppBar(
        title: Text(loc.cafeteriaMenu),
        elevation: 0,
      ),
      floatingActionButton: canManageMenu
          ? FloatingActionButton.extended(
              onPressed: () => _showAddMenuItemDialog(
                context,
                appState,
                currentMenu?.date ?? weekStart,
              ),
              backgroundColor: AppColors.goldDark,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Menyuya Əlavə Et',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Permission Banner (if admin or teacher with permission)
            if (canManageMenu)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: AppColors.goldDark.withAlpha(18),
                child: Row(
                  children: [
                    const Icon(
                      Icons.admin_panel_settings_outlined,
                      size: 16,
                      color: AppColors.goldDark,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'İdarəetmə aktivdir: Menyunu dəyişə, yeni yemək əlavə edə və silə bilərsiniz.',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.goldDark,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline_rounded,
                        color: AppColors.goldDark,
                        size: 18,
                      ),
                      tooltip: 'Yemək Əlavə Et',
                      onPressed: () => _showAddMenuItemDialog(
                        context,
                        appState,
                        currentMenu?.date ?? weekStart,
                      ),
                    ),
                  ],
                ),
              ),

            // Week Switcher — Bu həftə / Növbəti həftə / menyusu olan həftələr
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: weekChips
                      .map(
                        (ws) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildWeekChip(ws, thisWeekStart),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),

            // Days Switcher
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(weekMenus.length, (index) {
                    final isSelected = index == dayIndex;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: InkWell(
                        onTap: () => setState(() => _selectedDayIndex = index),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryAccent
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryAccent
                                  : AppColors.cardBorder,
                            ),
                          ),
                          child: Text(
                            '${weekMenus[index].dayName} ${_fmtDate(weekMenus[index].date)}',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            if (currentMenu != null) ...[
              // Daily Summary Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFB45309), Color(0xFFD97706)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: AppShadows.sm,
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
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${currentMenu.mealTime} • ${currentMenu.items.length} Çeşid',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Cəmi Kalori',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
                    ),
                  ],
                ),
              ),

              // Food Items List
              if (currentMenu.items.isEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.restaurant_menu_outlined,
                          size: 44,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Bu gün üçün menyu daxil edilməyib.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        if (canManageMenu) ...[
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.goldDark,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => _showAddMenuItemDialog(
                              context,
                              appState,
                              currentMenu.date,
                            ),
                            icon: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 16,
                            ),
                            label: const Text(
                              'İlk Yeməyi Əlavə Et',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: currentMenu.items
                        .asMap()
                        .entries
                        .map(
                          (entry) => _buildMenuItemCard(
                            context,
                            appState,
                            entry.value,
                            entry.key,
                            canManageMenu,
                            currentMenu.date,
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          ],
        ),
      ),
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
        margin: const EdgeInsets.only(top: 16, bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryAccent.withAlpha(30),
              AppColors.primaryAccent.withAlpha(10),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primaryAccent.withAlpha(60)),
        ),
        child: Row(
          children: [
            Text(
              item.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryAccent,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
            Container(
              height: 2,
              width: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryAccent,
                    AppColors.primaryAccent.withAlpha(0),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Normal yemək item-i
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              item.imageUrl,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
              errorBuilder: (_, e, s) => Container(
                width: 70,
                height: 70,
                color: const Color(0xFFF1F5F9),
                child: Icon(
                  Icons.restaurant_outlined,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StatusBadge(
                      label: item.category,
                      color: AppColors.primaryAccent,
                      fontSize: 9.5,
                    ),
                    Row(
                      children: [
                        Text(
                          '${item.calories} kkal • ${item.weightGram}',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (canManage) ...[
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (dCtx) {
                                  final dLoc = AppLocalizations.of(dCtx);
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    title: Text(dLoc.delete),
                                    content: Text(
                                      '"${item.name}" menyudan silinsin?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dCtx),
                                        child: Text(dLoc.cancel),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.danger,
                                        ),
                                        onPressed: () {
                                          appState.removeMenuItemFromDay(
                                            menuDate,
                                            itemIndex,
                                          );
                                          Navigator.pop(dCtx);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                dLoc.successfullyDeleted,
                                              ),
                                              backgroundColor: AppColors.danger,
                                            ),
                                          );
                                        },
                                        child: Text(
                                          dLoc.delete,
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(2),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                size: 16,
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (item.allergens.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 4,
                    runSpacing: 3,
                    children: item.allergens.map((allergen) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.danger.withAlpha(12),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: AppColors.danger.withAlpha(40),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              size: 10,
                              color: AppColors.danger,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              allergen,
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppColors.danger,
                                fontWeight: FontWeight.bold,
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldDark : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.goldDark : AppColors.cardBorder,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 2),
            if (offsetDays <= 7)
              Text(
                '${_fmtDate(start)} – ${_fmtDate(end)}',
                style: TextStyle(
                  color: isSelected ? Colors.white70 : AppColors.textMuted,
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
    // Hansı həftənin gününə əlavə olunur — admin bunu dəyişə bilər
    DateTime selectedDate = DateTime(
      menuDate.year,
      menuDate.month,
      menuDate.day,
    );
    String category = 'Əsas Yemək';
    final categories = [
      'Şorba',
      'Əsas Yemək',
      'Qarnir',
      'Salat',
      'Şirniyyat / İçki',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        final dLoc = AppLocalizations.of(ctx);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text('Menyuya Yeni Yemək Əlavə Et'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tarix seçici — hansı həftə/gün üçün daxil edirik
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 365),
                          ),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                          helpText: 'Yeməyin tarixini seçin',
                        );
                        if (picked != null) {
                          setDialogState(
                            () => selectedDate = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.cardBorder),
                          borderRadius: BorderRadius.circular(12),
                          color: AppColors.goldDark.withAlpha(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              color: AppColors.goldDark,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${_weekdayName(selectedDate.weekday)}, ${_fmtDate(selectedDate)} — bu günə əlavə olunacaq',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.goldDark,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.edit_calendar_outlined,
                              size: 16,
                              color: AppColors.goldDark,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Yeməyin Adı *',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(
                        labelText: 'Kateqoriya',
                      ),
                      items: categories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
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
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: weightCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Porsiya (qram) *',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: allergenCtrl,
                      decoration: InputDecoration(
                        labelText: '${dLoc.allergens} (vergüllə ayırın)',
                        hintText: 'Məs: Qlüten, Süd, Qoz',
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
                    backgroundColor: AppColors.goldDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Yeməyin adını qeyd edin!'),
                        ),
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
                      weightGram: weightCtrl.text.trim().isNotEmpty
                          ? weightCtrl.text.trim()
                          : '200g',
                      allergens: allergens,
                      imageUrl:
                          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
                    );

                    appState.addMenuItemToDay(selectedDate, newItem);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '"${newItem.name}" menyuya əlavə edildi!',
                        ),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  child: Text(
                    dLoc.add,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
