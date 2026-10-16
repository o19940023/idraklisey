import 'dart:async';

import 'package:flutter/material.dart';

/// Shared motion primitives used across the whole app.
///
/// Everything here is purely visual: no gesture arena participation, no
/// navigator logic changes — safe to wrap around existing widgets.

/// One-shot entrance animation: fades in and slides up slightly.
///
/// Plays once when first inserted into the tree. Replays only if the widget
/// is recreated (e.g. an empty-state that reappears after a reload).
class FadeIn extends StatefulWidget {
  const FadeIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.offset = const Offset(0, 0.03),
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;
  final Curve curve;

  @override
  State<FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<FadeIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: widget.curve,
  );
  late final Animation<Offset> _slide =
      Tween<Offset>(begin: widget.offset, end: Offset.zero).animate(_fade);

  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Subtle scale-down while the wrapped area is pressed.
///
/// Uses a raw [Listener], so it never competes with buttons, ink wells or
/// gesture detectors underneath — taps keep working exactly as before.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.pressedScale = 0.97,
    this.duration = const Duration(milliseconds: 110),
    this.enabled = true,
  });

  final Widget child;
  final double pressedScale;
  final Duration duration;
  final bool enabled;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        if (widget.enabled) setState(() => _pressed = true);
      },
      onPointerUp: (_) {
        if (_pressed) setState(() => _pressed = false);
      },
      onPointerCancel: (_) {
        if (_pressed) setState(() => _pressed = false);
      },
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Comfortable stagger delay for list/grid entrance animations.
///
/// [index] is the item position; returns a delay that grows linearly but is
/// capped so long lists do not keep animating forever.
Duration staggerDelay(
  int index, {
  int baseMs = 40,
  int stepMs = 55,
  int maxMs = 420,
}) {
  return Duration(
    milliseconds: (baseMs + index * stepMs).clamp(0, maxMs),
  );
}

/// Smooth "fade-through" page transition for the whole app.
///
/// The incoming page fades in with a gentle upward slide while the page
/// being covered fades part-way out — calmer and more premium than the
/// default zoom transition, and it still supports swipe-back on iOS.
class FadeThroughPageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeThroughPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _FadeThroughPageTransition(
      animation: animation,
      secondaryAnimation: secondaryAnimation,
      child: child,
    );
  }
}

class _FadeThroughPageTransition extends StatelessWidget {
  const _FadeThroughPageTransition({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Incoming page: quick fade-in with a soft rise.
    final fadeIn = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.2, 1, curve: Curves.easeOut),
    );
    final slideIn = Tween<Offset>(begin: const Offset(0, 0.015), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );

    // When this page gets covered by a new route: recede instead of zooming.
    final fadeOut = Tween<double>(begin: 1.0, end: 0.35).animate(
      CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeOut),
    );

    return FadeTransition(
      opacity: fadeOut,
      child: SlideTransition(
        position: slideIn,
        child: FadeTransition(opacity: fadeIn, child: child),
      ),
    );
  }
}
