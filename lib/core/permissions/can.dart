import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../session/session_controller.dart';

/// Conditionally renders [child] only when the authenticated user holds
/// [permission] (or any of [anyOf]). Mirrors the web `@can` directive.
class Can extends StatelessWidget {
  const Can({
    super.key,
    this.permission,
    this.anyOf,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  }) : assert(permission != null || anyOf != null, 'permission or anyOf required');

  final String? permission;
  final List<String>? anyOf;
  final Widget child;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final allowed = permission != null
        ? session.can(permission!)
        : session.canAny(anyOf ?? const []);

    return allowed ? child : fallback;
  }
}

/// Non-widget helper for imperative checks inside controllers/services.
extension PermissionLookup on BuildContext {
  bool can(String permission) => read<SessionController>().can(permission);
}
