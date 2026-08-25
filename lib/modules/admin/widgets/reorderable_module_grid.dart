// Sürükle-Bırak Modül Grid Widgetı
// Admin, Teacher, Student və Parent panelləri üçün ümumi istifadə

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../data/models/user_preferences_model.dart';

class ReorderableModuleGrid extends StatefulWidget {
  final List<ModuleItem> modules;
  final Function(List<ModuleItem>) onReorder;
  final bool isReorderMode;
  final Function(String moduleId, BuildContext context)? onModuleTap;
  final Map<String, dynamic>? dynamicData; // subtitle üçün dinamik veri

  const ReorderableModuleGrid({
    super.key,
    required this.modules,
    required this.onReorder,
    this.isReorderMode = false,
    this.onModuleTap,
    this.dynamicData,
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
      'qr_code_rounded': Icons.qr_code_rounded,
      'qr_code_scanner_rounded': Icons.qr_code_scanner_rounded,
      'groups_rounded': Icons.groups_rounded,
      'groups_outlined': Icons.groups_outlined,
      'edit_note_rounded': Icons.edit_note_rounded,
      'edit_note_outlined': Icons.edit_note_outlined,
      'view_timeline_rounded': Icons.view_timeline_rounded,
      'assignment_rounded': Icons.assignment_rounded,
      'assignment_outlined': Icons.assignment_outlined,
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

  String _getSubtitle(ModuleItem module) {
    if (widget.dynamicData != null && widget.dynamicData!.containsKey(module.id)) {
      return widget.dynamicData![module.id].toString();
    }
    return module.subtitle;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isReorderMode) {
      // Siyahı Şəklində Sıralama Rejimi (Alternativ ReorderableListView)
      return ReorderableListView.builder(
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
                  elevation: 10,
                  shadowColor: Colors.black45,
                  borderRadius: BorderRadius.circular(18),
                  child: child,
                ),
              );
            },
            child: child,
          );
        },
        itemBuilder: (context, index) {
          final module = _modules[index];
          return _buildReorderListTile(module, index);
        },
      );
    }

    // Telefon Tərzi Canlı Sürükle-Bırak Qrid (Home Screen Grid Drag & Drop)
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12) / 2;
        final itemHeight = itemWidth / 1.2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: _modules.length,
          itemBuilder: (context, index) {
            final module = _modules[index];
            return _buildDraggableGridItem(module, itemWidth, itemHeight);
          },
        );
      },
    );
  }

  Widget _buildDraggableGridItem(ModuleItem module, double width, double height) {
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
        setState(() {
          _hoveredTargetId = null;
        });
        _swapModules(details.data.id, module.id);
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
          // Sürüklənərkən barmaq altında görünən vizual kart (Smartphone icon lift effect)
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: width,
              height: height,
              child: Transform.scale(
                scale: 1.06,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.primaryAccent,
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryAccent.withAlpha(80),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: _getColorFromHex(module.accentColor).withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getColorFromHex(module.accentColor).withAlpha(80),
                              ),
                            ),
                            child: Icon(
                              _getIconFromString(module.icon),
                              color: _getColorFromHex(module.accentColor),
                              size: 20,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primaryAccent.withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.drag_indicator_rounded,
                              size: 14,
                              color: AppColors.primaryAccent,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            module.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _getSubtitle(module),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Sürüklənərkən arxada qalan yer
          childWhenDragging: Container(
            decoration: BoxDecoration(
              color: AppColors.cardBorder.withAlpha(25),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.primaryAccent.withAlpha(80),
                width: 1.5,
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.add_circle_outline_rounded,
                color: AppColors.primaryAccent.withAlpha(120),
                size: 28,
              ),
            ),
          ),
          // Normal qrid kartı
          child: _buildModuleTile(module, isHovered, isDraggingSelf),
        );
      },
    );
  }

  Widget _buildModuleTile(ModuleItem module, bool isHovered, bool isDraggingSelf) {
    final iconData = _getIconFromString(module.icon);
    final accentColor = _getColorFromHex(module.accentColor);
    final subtitleText = _getSubtitle(module);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: isHovered
            ? accentColor.withAlpha(20)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isHovered
              ? accentColor
              : AppColors.cardBorder,
          width: isHovered ? 2.0 : 1.0,
        ),
        boxShadow: isHovered ? AppShadows.md : AppShadows.sm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (widget.onModuleTap != null) {
              widget.onModuleTap!(module.id, context);
            }
          },
          onLongPress: () {
            // Haptic Feedback for long press
            HapticFeedback.mediumImpact();
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: accentColor.withAlpha(18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: accentColor.withAlpha(35),
                          width: 1,
                        ),
                      ),
                      child: Icon(iconData, color: accentColor, size: 20),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.cardBorder.withAlpha(60),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.arrow_outward_rounded,
                            size: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReorderListTile(ModuleItem module, int index) {
    final iconData = _getIconFromString(module.icon);
    final accentColor = _getColorFromHex(module.accentColor);
    final subtitleText = _getSubtitle(module);

    return Container(
      key: ValueKey(module.id),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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
          ),
          child: Icon(iconData, color: accentColor, size: 22),
        ),
        title: Text(
          module.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitleText,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Icon(
          Icons.drag_handle_rounded,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

