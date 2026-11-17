import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/idrak_logo.dart';
import '../../../providers/app_state.dart';
import '../../navigation/main_screen.dart';
import 'login_screen.dart';

/// Single entry point: restores the session, then shows login or the luxury MainScreen.
class StartupGate extends StatefulWidget {
  const StartupGate({super.key});

  @override
  State<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<StartupGate> {
  bool _minimumSplashDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      context.read<SessionController>().restore(),
      Future.delayed(const Duration(milliseconds: 900)),
    ]);

    if (mounted) {
      final session = context.read<SessionController>();
      if (session.isAuthenticated) {
        context.read<AppState>().syncFromSession(session);
      }
      setState(() => _minimumSplashDone = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final appState = context.watch<AppState>();

    if (session.isRestoring || !_minimumSplashDone) {
      return const _BrandSplash();
    }

    if (session.isAuthenticated) {
      if (appState.currentUser == null ||
          appState.currentUser?.id != session.profile?.id.toString() ||
          (session.profile?.isParent == true && appState.children.isEmpty)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.read<AppState>().syncFromSession(session);
          }
        });
      }
      return const MainScreen(key: ValueKey('main'));
    }

    return const LoginScreen(key: ValueKey('login'));
  }
}

class _BrandSplash extends StatelessWidget {
  const _BrandSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const IdrakLogo(size: 84)
                  .animate()
                  .fadeIn(duration: 420.ms)
                  .scale(begin: const Offset(0.92, 0.92), end: const Offset(1, 1)),
              const SizedBox(height: 18),
              const Text(
                'İDRAK LİSEYİ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: 1.4,
                ),
              ).animate().fadeIn(delay: 120.ms),
              const SizedBox(height: 26),
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white70),
              ).animate().fadeIn(delay: 260.ms),
            ],
          ),
        ),
      ),
    );
  }
}
