import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/navigation_utils.dart';
import '../../../core/widgets/idrak_logo.dart';
import '../../../core/widgets/motion.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/app_state.dart';
import '../../shared/widgets/identity_card_kit.dart';

class TeacherIdCardScreen extends StatefulWidget {
  const TeacherIdCardScreen({super.key});

  @override
  State<TeacherIdCardScreen> createState() => _TeacherIdCardScreenState();
}

class _TeacherIdCardScreenState extends State<TeacherIdCardScreen>
    with SingleTickerProviderStateMixin {
  static const _cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF171B2C), Color(0xFF0F1524), Color(0xFF090B14)],
  );

  late final AnimationController _flipController;
  late final Animation<double> _flipAnimation;

  bool _showBack = false;
  bool _isTurnstileBusy = false;
  bool _isCardLocked = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _flipAnimation = CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOutCubicEmphasized,
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _flipCard() {
    HapticFeedback.mediumImpact();
    setState(() => _showBack = !_showBack);
    if (MediaQuery.disableAnimationsOf(context)) {
      _flipController.value = _showBack ? 1.0 : 0.0;
      return;
    }
    if (_showBack) {
      _flipController.forward();
    } else {
      _flipController.reverse();
    }
  }

  void _openQrSheet(
    BuildContext context,
    String teacherName,
    String teacherPosition,
    String teacherCode,
    Color accent,
  ) {
    showIdentityQrSheet(
      context,
      title: 'Müəllim QR Kodu',
      subtitle: 'Turniket və kabinet skanerləri üçün açın',
      displayName: '$teacherName • $teacherPosition',
      code: teacherCode,
      accent: accent,
    );
  }

  void _activateTurnstile() {
    if (_isTurnstileBusy) return;
    if (_isCardLocked) {
      HapticFeedback.selectionClick();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.danger,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: const Row(
            children: [
              Icon(Icons.lock_rounded, color: Colors.white, size: 16),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Pedaqoji vəsiqə dondurulub. Əvvəlcə kilidi açın.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }
    HapticFeedback.heavyImpact();
    setState(() => _isTurnstileBusy = true);
    Future<void>.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _isTurnstileBusy = false);
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Müəllim NFC Açarı Aktivdir • Turniket və Müəllimlər Otağı Açıldı',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _toggleLock() {
    HapticFeedback.selectionClick();
    setState(() => _isCardLocked = !_isCardLocked);
  }

  Widget _entrance(BuildContext context, int index, Widget child) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return child
        .animate()
        .fadeIn(
          duration: 420.ms,
          delay: staggerDelay(index),
          curve: Curves.easeOutCubic,
        )
        .slideY(
          begin: 0.04,
          duration: 420.ms,
          delay: staggerDelay(index),
          curve: Curves.easeOutCubic,
        );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final appState = context.watch<AppState>();
    final AppUser? user = appState.currentUser;
    final List<String> classes = appState.currentTeacherClasses;

    final teacherName = user?.fullName ?? 'Pedaqoq';
    final teacherPosition = user?.position ?? 'Fənn müəllimi';
    final teacherCode = user?.idrakCode ?? 'IDR-TCH-001';
    final accent = palette.brandGold;

    return Scaffold(
      backgroundColor: palette.bgBase,
      appBar: AppBar(
        title: const Text('Pedaqoji Vəsiqə'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => handleBackNavigation(context),
          icon: Icon(Icons.adaptive.arrow_back),
        ),
        actions: [
          IconButton(
            tooltip: 'QR kodu göstər',
            onPressed: () => _openQrSheet(
              context,
              teacherName,
              teacherPosition,
              teacherCode,
              accent,
            ),
            icon: const Icon(Icons.qr_code_scanner_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                children: [
                  _entrance(
                    context,
                    0,
                    _buildCard(context, user, classes, accent),
                  ),
                  const SizedBox(height: 14),
                  _entrance(context, 1, _buildHint(palette)),
                  const SizedBox(height: 20),
                  _entrance(
                    context,
                    2,
                    _buildActions(
                      context,
                      teacherName,
                      teacherPosition,
                      teacherCode,
                      accent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _entrance(context, 3, _buildStatusLine(palette, colorScheme)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    AppUser? user,
    List<String> classes,
    Color accent,
  ) {
    return GestureDetector(
      onTap: _flipCard,
      child: Semantics(
        button: true,
        label: _showBack ? 'Kartı ön tərəfə çevir' : 'Kartı arxa tərəfə çevir',
        child: AnimatedSize(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 520),
          curve: Curves.easeInOutCubicEmphasized,
          child: AnimatedBuilder(
            animation: _flipAnimation,
            builder: (context, _) {
              final angle = _flipAnimation.value * pi;
              final backVisible = angle > pi / 2;
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0012)
                  ..rotateY(angle),
                alignment: Alignment.center,
                child: IdentityCardShell(
                  accent: accent,
                  gradient: _cardGradient,
                  child: backVisible
                      ? Transform(
                          transform: Matrix4.identity()..rotateY(pi),
                          alignment: Alignment.center,
                          child: _buildBack(user, classes, accent),
                        )
                      : _buildFront(user, accent),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFront(AppUser? user, Color accent) {
    final teacherName = user?.fullName ?? 'Pedaqoq';
    final teacherPosition = user?.position ?? 'Fənn müəllimi';
    final teacherCode = user?.idrakCode ?? 'IDR-TCH-001';
    final subject = user?.subject?.trim() ?? '';
    final room = user?.roomNumber?.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFrontHeader(accent),
          const SizedBox(height: 12),
          const _CardDivider(),
          const SizedBox(height: 12),
          _buildIdentity(
            teacherName,
            teacherPosition,
            teacherCode,
            user?.photoUrl,
            accent,
          ),
          const SizedBox(height: 12),
          const _CardDivider(),
          const SizedBox(height: 12),
          _buildBottomRow(
            context,
            teacherName,
            teacherPosition,
            teacherCode,
            subject,
            room,
            accent,
          ),
          const SizedBox(height: 10),
          const Text(
            'Bu vəsiqə İdrak Liseyinin rəsmi sənədidir.',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white38,
              fontSize: 8.5,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrontHeader(Color accent) {
    final statusTint = _isCardLocked ? AppColors.danger : AppColors.success;
    final statusColor = _isCardLocked
        ? const Color(0xFFFCA5A5)
        : const Color(0xFF34D399);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: accent.withValues(alpha: 0.30)),
          ),
          child: const IdrakLogo(size: 24),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'İDRAK LİSEYİ',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'PEDAQOJİ HEYƏT',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: accent.withValues(alpha: 0.85),
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusTint.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: statusTint.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: statusTint,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                _isCardLocked ? 'DONDURULUB' : 'AKTİV',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.contactless_rounded,
          color: Colors.white.withValues(alpha: 0.7),
          size: 18,
        ),
      ],
    );
  }

  Widget _buildIdentity(
    String teacherName,
    String teacherPosition,
    String teacherCode,
    String? photoUrl,
    Color accent,
  ) {
    return Row(
      children: [
        IdentityCardPhoto(
          name: teacherName,
          photoUrl: photoUrl,
          accent: accent,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                teacherName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                teacherPosition,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                teacherCode,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: accent,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomRow(
    BuildContext context,
    String teacherName,
    String teacherPosition,
    String teacherCode,
    String subject,
    String room,
    Color accent,
  ) {
    return Row(
      children: [
        Expanded(
          child: IdentityCardField(
            label: 'FƏNN',
            value: subject.isEmpty ? '—' : subject,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: IdentityCardField(
            label: 'OTAQ',
            value: room.isEmpty ? '—' : room,
          ),
        ),
        const SizedBox(width: 12),
        IdentityCardQrTile(
          data: teacherCode,
          onTap: () => _openQrSheet(
            context,
            teacherName,
            teacherPosition,
            teacherCode,
            accent,
          ),
        ),
      ],
    );
  }

  Widget _buildBack(AppUser? user, List<String> classes, Color accent) {
    final phone = user?.phone.trim() ?? '';
    final email = (user?.email ?? '').trim();
    final subject = user?.subject?.trim() ?? '';
    final room = user?.roomNumber?.trim() ?? '';
    final institutionId = user?.id ?? '—';

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: accent.withValues(alpha: 0.28)),
                ),
                child: Icon(Icons.school_rounded, color: accent, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TƏDRİS MƏLUMATLARI',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.9,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Siniflər, fənn və kabinet qeydləri',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.54),
                        fontSize: 8.5,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _CardDivider(),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildClassesRow(classes, accent),
                if (subject.isNotEmpty)
                  IdentityCardInfoRow(label: 'Fənn', value: subject),
                if (room.isNotEmpty) IdentityCardInfoRow(label: 'Otaq', value: room),
                if (phone.isNotEmpty)
                  IdentityCardInfoRow(label: 'Telefon', value: phone),
                if (email.isNotEmpty)
                  IdentityCardInfoRow(label: 'E-poçt', value: email),
                const IdentityCardInfoRow(
                  label: 'Müəssisə',
                  value: 'İdrak Liseyi, Bakı',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'İD: $institutionId',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 8.5,
                    fontFamily: 'monospace',
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified_rounded, color: Color(0xFF34D399), size: 11),
                  SizedBox(width: 4),
                  Text(
                    'TƏSDİQLƏNİB',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClassesRow(List<String> classes, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Siniflər',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.54),
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: classes.isEmpty
                ? Text(
                    'Təyin edilməyib',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.54),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.end,
                    children: classes
                        .map(
                          (className) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.32),
                              ),
                            ),
                            child: Text(
                              className,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHint(AppPalette palette) {
    final text = _showBack
        ? 'Ön tərəfə qayıtmaq üçün toxunun'
        : 'Çevirmək üçün karta toxunun';
    final animated = !MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: animated ? const Duration(milliseconds: 200) : Duration.zero,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: Row(
        key: ValueKey<bool>(_showBack),
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sync_rounded, size: 13, color: palette.textMuted),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.textMuted,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(
    BuildContext context,
    String teacherName,
    String teacherPosition,
    String teacherCode,
    Color accent,
  ) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Row(
        children: [
          Expanded(
            child: IdentityCardAction(
              icon: Icons.qr_code_scanner_rounded,
              label: 'QR kod',
              accent: accent,
              onTap: () => _openQrSheet(
                context,
                teacherName,
                teacherPosition,
                teacherCode,
                accent,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: IdentityCardAction(
              icon: Icons.nfc_rounded,
              label: 'Turniket',
              accent: accent,
              busy: _isTurnstileBusy,
              onTap: _activateTurnstile,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: IdentityCardAction(
              icon: _isCardLocked ? Icons.lock_open_rounded : Icons.lock_rounded,
              label: _isCardLocked ? 'Kilidi aç' : 'Kilidlə',
              accent: accent,
              onTap: _toggleLock,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusLine(AppPalette palette, ColorScheme colorScheme) {
    final locked = _isCardLocked;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          locked ? Icons.lock_rounded : Icons.verified_rounded,
          size: 14,
          color: locked ? colorScheme.error : AppColors.success,
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            locked
                ? 'Vəsiqə dondurulub — keçid dayandırılıb'
                : 'Təsdiqlənmiş pedaqoq kimliyi',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: locked ? colorScheme.error : palette.textMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _CardDivider extends StatelessWidget {
  const _CardDivider();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: Colors.white.withValues(alpha: 0.10));
  }
}
