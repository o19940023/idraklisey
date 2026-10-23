import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class AppSearchBar extends StatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final bool autofocus;

  const AppSearchBar({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.autofocus = false,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  TextEditingController? _ownedController;
  final FocusNode _focusNode = FocusNode();

  TextEditingController get _effectiveController =>
      widget.controller ?? (_ownedController ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    _effectiveController.addListener(_handleTextChanged);
  }

  @override
  void didUpdateWidget(AppSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _effectiveController.addListener(_handleTextChanged);
    }
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_handleTextChanged);
    _ownedController?.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final focused = _focusNode.hasFocus;
    final hasText = _effectiveController.text.isNotEmpty;

    return Semantics(
      label: widget.hintText ?? 'Axtarış',
      textField: true,
      child: AnimatedBuilder(
        animation: Listenable.merge([_focusNode, _effectiveController]),
        builder: (context, _) => Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: palette.surface2,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: focused ? palette.brandRoyal : palette.borderHairline,
              width: focused ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _effectiveController,
                  focusNode: _focusNode,
                  autofocus: widget.autofocus,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  maxLines: 1,
                  textAlignVertical: TextAlignVertical.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: widget.hintText,
                    hintStyle: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              if (hasText)
                GestureDetector(
                  onTap: () {
                    _effectiveController.clear();
                    widget.onClear?.call();
                    widget.onChanged?.call('');
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: palette.borderHairline.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
