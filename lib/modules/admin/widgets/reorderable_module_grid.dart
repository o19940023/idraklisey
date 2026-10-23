// Sürükle-Bırak Modül Grid Widgetı
// Admin, Teacher, Student və Parent panelləri üçün ümumi istifadə

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/widgets/motion.dart';
import '../../../data/models/user_preferences_model.dart';
import '../../../l10n/app_localizations.dart';

class ReorderableModuleGrid extends StatefulWidget {
  final List<ModuleItem> modules;
  final Function(List<ModuleItem>) onReorder;
  final bool isReorderMode;
  final Function(String moduleId, BuildContext context)? onModuleTap;
  final Map<String, dynamic>? dynamicData; // subtitle üçün dinamik veri
  final bool allowTwoLineTitle;

  const ReorderableModuleGrid({
    super.key,
    required this.modules,
    required this.onReorder,
    this.isReorderMode = false,
    this.onModuleTap,
    this.dynamicData,
    this.allowTwoLineTitle = false,
  });

  @override
  State<ReorderableModuleGrid> createState() => _ReorderableModuleGridState();
}

class _ReorderableModuleGridState extends State<ReorderableModuleGrid> {
  late List<ModuleItem> _modules;
  String? _currentlyDraggingId;
  String? _hoveredTargetId;

  @override
  void initState() {
    super.initState();
    _modules = List.from(widget.modules);
  }

  @override
  void didUpdateWidget(ReorderableModuleGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.modules != oldWidget.modules) {
      _modules = List.from(widget.modules);
    }
  }

  void _onReorderList(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _modules.removeAt(oldIndex);
      _modules.insert(newIndex, item);

      for (int i = 0; i < _modules.length; i++) {
        _modules[i] = _modules[i].copyWith(orderIndex: i);
      }
    });

    widget.onReorder(_modules);
  }

  void _swapModules(String draggedId, String targetId) {
    if (draggedId == targetId) return;

    final oldIndex = _modules.indexWhere((m) => m.id == draggedId);
    final newIndex = _modules.indexWhere((m) => m.id == targetId);

    if (oldIndex != -1 && newIndex != -1) {
      HapticFeedback.selectionClick();
      setState(() {
        final item = _modules.removeAt(oldIndex);
        _modules.insert(newIndex, item);

        for (int i = 0; i < _modules.length; i++) {
          _modules[i] = _modules[i].copyWith(orderIndex: i);
        }
      });

      widget.onReorder(_modules);
    }
  }

  IconData _getIconFromString(String iconName) {
    final iconMap = {
      'school_rounded': Icons.school_rounded,
      'class_rounded': Icons.class_rounded,
      'calendar_month_rounded': Icons.calendar_month_rounded,
      'calendar_month_outlined': Icons.calendar_month_outlined,
      'manage_accounts_rounded': Icons.manage_accounts_rounded,
      'manage_accounts_outlined': Icons.manage_accounts_outlined,
      'admin_panel_settings_rounded': Icons.admin_panel_settings_rounded,
      'support_agent_rounded': Icons.support_agent_rounded,
      'support_agent_outlined': Icons.support_agent_outlined,
      'analytics_rounded': Icons.analytics_rounded,
      'analytics_outlined': Icons.analytics_outlined,
      'restaurant_menu_rounded': Icons.restaurant_menu_rounded,
      'campaign_rounded': Icons.campaign_rounded,
      'task_rounded': Icons.task_rounded,
      'task_outlined': Icons.task_outlined,
      'qr_code_rounded': Icons.qr_code_rounded,
      'qr_code_scanner_rounded': Icons.qr_code_scanner_rounded,
      'groups_rounded': Icons.groups_rounded,
      'groups_outlined': Icons.groups_outlined,
      'edit_note_rounded': Icons.edit_note_rounded,
      'edit_note_outlined': Icons.edit_note_outlined,
      'view_timeline_rounded': Icons.view_timeline_rounded,
      'assignment_rounded': Icons.assignment_rounded,
      'assignment_outlined': Icons.assignment_outlined,
      'menu_book_rounded': Icons.menu_book_rounded,
      'menu_book_outlined': Icons.menu_book_outlined,
      'assignment_turned_in_rounded': Icons.assignment_turned_in_rounded,
      'badge_rounded': Icons.badge_rounded,
      'badge_outlined': Icons.badge_outlined,
      'insights_rounded': Icons.insights_rounded,
      'insights_outlined': Icons.insights_outlined,
      'grid_view_rounded': Icons.grid_view_rounded,
      'grid_view_outlined': Icons.grid_view_outlined,
      'local_library_rounded': Icons.local_library_rounded,
      'local_library_outlined': Icons.local_library_outlined,
      'account_circle_rounded': Icons.account_circle_rounded,
      'favorite_rounded': Icons.favorite_rounded,
      'favorite_outline_rounded': Icons.favorite_outline_rounded,
      'video_camera_front_rounded': Icons.video_camera_front_rounded,
      'video_camera_front_outlined': Icons.video_camera_front_outlined,
      'mic_external_on_rounded': Icons.mic_external_on_rounded,
      'mic_rounded': Icons.mic_rounded,
      'notifications_active_rounded': Icons.notifications_active_rounded,
      'dashboard_rounded': Icons.dashboard_rounded,
      'dashboard_outlined': Icons.dashboard_outlined,
    };
    return iconMap[iconName] ?? Icons.apps_rounded;
  }

  Color _getColorFromHex(String hexColor) {
    try {
      final hex = hexColor.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return AppColors.primaryAccent;
    }
  }

  String _getSubtitle(ModuleItem module, AppLocalizations loc) {
    if (widget.dynamicData != null &&
        widget.dynamicData!.containsKey(module.id)) {
      return widget.dynamicData![module.id].toString();
    }
    return module.getLocalizedSubtitle(loc);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (widget.isReorderMode) {
      // Siyahı Şəklində Sıralama Rejimi - Material wrap needed
      return Material(
        color: Colors.transparent,
        child: ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _modules.length,
          onReorder: _onReorderList,
          proxyDecorator: (child, index, animation) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final scale = 1.0 + (animation.value * 0.04);
                return Transform.scale(
                  scale: scale,
                  child: Material(
                    elevation: 12,
                    shadowColor: Colors.black38,
                    borderRadius: BorderRadius.circular(20),
                    child: child,
                  ),
                );
              },
              child: child,
            );
          },
          itemBuilder: (context, index) {
            final module = _modules[index];
            return _buildReorderListTile(module, index, loc);
          },
        ),
      );
    }

    // Telefon Tərzi Canlı Sürükle-Bırak Qrid (iOS Squircle App Grid)
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 3 : 2;
        const spacing = 10.0;
        final tileHeight =
            widget.allowTwoLineTitle && columns == 2 ? 92.0 : 86.0;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            mainAxisExtent: tileHeight,
          ),
          itemCount: _modules.length,
          itemBuilder: (context, index) {
            final module = _modules[index];
            // Paneldəki kartlar bir-birinin ardınca yumşaq "giriş" edir.
            // Key sayəsində sürükləyib yerini dəyişəndə animasiya təkrar
            // oynamır — yalnız ilk açılışda.
            return FadeIn(
              key: ValueKey('entrance_${module.id}'),
              delay: staggerDelay(index),
              duration: const Duration(milliseconds: 380),
              offset: const Offset(0, 0.04),
              child: _buildDraggableGridItem(module, itemWidth, tileHeight, loc),
            );
          },
        );
      },
    );
  }

  Widget _buildDraggableGridItem(
    ModuleItem module,
    double width,
    double height,
    AppLocalizations loc,
  ) {
    final isHovered = _hoveredTargetId == module.id;
    final isDraggingSelf = _currentlyDraggingId == module.id;

    return DragTarget<ModuleItem>(
      onWillAcceptWithDetails: (details) {
        if (details.data.id != module.id) {
          setState(() {
            _hoveredTargetId = module.id;
          });
          return true;
        }
        return false;
      },
      onLeave: (data) {
        if (_hoveredTargetId == module.id) {
          setState(() {
            _hoveredTargetId = null;
          });
        }
      },
      onAcceptWithDetails: (details) {
        _swapModules(details.data.id, module.id);
        setState(() {
          _currentlyDraggingId = null;
          _hoveredTargetId = null;
        });
      },
      builder: (context, candidateData, rejectedData) {
        return LongPressDraggable<ModuleItem>(
          data: module,
          delay: const Duration(milliseconds: 220),
          onDragStarted: () {
            HapticFeedback.heavyImpact();
            setState(() {
              _currentlyDraggingId = module.id;
            });
          },
          onDragEnd: (details) {
            setState(() {
              _currentlyDraggingId = null;
              _hoveredTargetId = null;
            });
          },
          onDraggableCanceled: (velocity, offset) {
            setState(() {
              _currentlyDraggingId = null;
              _hoveredTargetId = null;
            });
          },
          // Sürüklənərkən barmaq altında görünən vizual kart (iOS App Icon Lift)
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: width,
              height: height,
              child: Transform.scale(
                scale: 1.05,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: _getColorFromHex(module.accentColor).withAlpha(60),
                        blurRadius: 24,
                        spreadRadius: 2,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: _buildModuleTile(module, true, false, loc),
                ),
              ),
            ),
          ),
          // Sürüklənərkən arxada qalan yer
          childWhenDragging: Container(
            decoration: BoxDecoration(
              color: AppColors.cardBorder.withAlpha(20),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.primaryAccent.withAlpha(70),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.add_circle_outline_rounded,
                color: AppColors.primaryAccent.withAlpha(100),
                size: 28,
              ),
            ),
          ),
          // Normal qrid kartı
          child: _buildModuleTile(module, isHovered, isDraggingSelf, loc),
        );
      },
    );
  }

  Widget _buildModuleTile(
    ModuleItem module,
    bool isHovered,
    bool isDraggingSelf,
    AppLocalizations loc,
  ) {
    final iconData = _getIconFromString(module.icon);
    final accentColor = _getColorFromHex(module.accentColor);
    final subtitleText = _getSubtitle(module, loc);
    final palette = AppPalette.of(context);

    return PressableScale(
      pressedScale: 0.97,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: isDraggingSelf ? 0.45 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isHovered
                ? Color.alphaBlend(
                    accentColor.withValues(alpha: 0.08),
                    palette.surface1,
                  )
                : palette.surface1,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isHovered
                  ? accentColor.withValues(alpha: 0.55)
                  : palette.borderHairline,
              width: isHovered ? 1.4 : 1,
            ),
            boxShadow: isHovered
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                if (widget.onModuleTap != null) {
                  widget.onModuleTap!(module.id, context);
                }
              },
              borderRadius: BorderRadius.circular(18),
              child: Semantics(
                label: '${module.getLocalizedTitle(loc)}, $subtitleText',
                button: true,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: AppColors.duoTint(accentColor),
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Icon(iconData, color: accentColor, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              module.getLocalizedTitle(loc),
                              maxLines: widget.allowTwoLineTitle ? 2 : 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.12,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.onSurface,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitleText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: palette.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: accentColor.withValues(alpha: 0.65),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildReorderListTile(
    ModuleItem module,
    int index,
    AppLocalizations loc,
  ) {
    final iconData = _getIconFromString(module.icon);
    final accentColor = _getColorFromHex(module.accentColor);
    final subtitleText = _getSubtitle(module, loc);

    return Container(
      key: ValueKey(module.id),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppShadows.sm,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: accentColor.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor.withAlpha(40)),
          ),
          child: Icon(iconData, color: accentColor, size: 22),
        ),
        title: Text(
          module.getLocalizedTitle(loc),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14.5,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitleText,
          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.drag_handle_rounded,
            color: AppColors.primaryAccent,
            size: 20,
          ),
        ),
      ),
    );
  }
}
