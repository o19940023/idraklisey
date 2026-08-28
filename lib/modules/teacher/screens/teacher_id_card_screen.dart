import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/idrak_logo.dart';
import '../../../core/utils/navigation_utils.dart';
import '../../../providers/app_state.dart';
import '../../../data/models/user_model.dart';

class TeacherIdCardScreen extends StatefulWidget {
  const TeacherIdCardScreen({super.key});

  @override
  State<TeacherIdCardScreen> createState() => _TeacherIdCardScreenState();
}

class _TeacherIdCardScreenState extends State<TeacherIdCardScreen>
    with TickerProviderStateMixin {
  late AnimationController _flipController;
  late AnimationController _goldSheenController;
  late Animation<double> _flipAnimation;
  bool _showBack = false;
  bool _isNfcActive = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _flipAnimation = CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOutBack,
    );

    _goldSheenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _flipController.dispose();
    _goldSheenController.dispose();
    super.dispose();
  }

  void _flipCard() {
    HapticFeedback.mediumImpact();
    if (_showBack) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() {
      _showBack = !_showBack;
    });
  }

  void _triggerNfc() {
    HapticFeedback.heavyImpact();
    setState(() => _isNfcActive = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _isNfcActive = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text('Müəllim NFC Keçidi • Turniket və Otaq Açarı Aktivdir'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    });
  }

  void _showZoomedQrModal(
    BuildContext context,
    String data,
    String title,
    String subtitle,
  ) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
            decoration: BoxDecoration(
              color: const Color(0xFF0C101C).withAlpha(245),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(color: const Color(0xFFD4AF37).withAlpha(60)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFFFDF79),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withAlpha(120),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: data,
                    version: QrVersions.auto,
                    size: 220,
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withAlpha(40),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        color: Color(0xFFFFDF79),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'KOD: $data',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Müəllim kabineti, laboratoriya və turniket üçün yüksək kontrastlı QR',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final user = appState.currentUser;
    final teacherClasses = appState.currentTeacherClasses;

    final teacherCode = user?.idrakCode ?? 'IDR-TCH-001';
    final teacherName = user?.fullName ?? 'Müəllim';
    final teacherPosition = user?.position ?? 'Pedaqoji Heyət / Müəllim';

    return Scaffold(
      backgroundColor: const Color(0xFF060912),
      appBar: AppBar(
        title: const Text(
          'Rəqəmsal Müəllim Vəsiqəsi',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16.5,
            letterSpacing: -0.2,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
          onPressed: () => handleBackNavigation(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFD4AF37).withAlpha(25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withAlpha(60),
                ),
              ),
              child: const Icon(
                Icons.qr_code_rounded,
                color: Color(0xFFFFDF79),
                size: 18,
              ),
            ),
            tooltip: 'Böyük QR Göstər',
            onPressed: () => _showZoomedQrModal(
              context,
              teacherCode,
              'Müəllim Giriş & İcazə QR',
              '$teacherName • $teacherCode',
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Background ambient luxury gold light
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD4AF37).withAlpha(35),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            left: -50,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1E3A8A).withAlpha(35),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              children: [
                // Segmented Switcher (Ön / Arxa Tərəf)
                ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(12),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white.withAlpha(20)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (_showBack) _flipCard();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                gradient: !_showBack
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFFD4AF37),
                                          Color(0xFFAA7A1E),
                                        ],
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: !_showBack
                                    ? [
                                        BoxShadow(
                                          color: const Color(
                                            0xFFD4AF37,
                                          ).withAlpha(80),
                                          blurRadius: 12,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.badge_rounded,
                                    size: 15,
                                    color: !_showBack
                                        ? Colors.black87
                                        : Colors.white60,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Ön Tərəf',
                                    style: TextStyle(
                                      color: !_showBack
                                          ? Colors.black87
                                          : Colors.white60,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              if (!_showBack) _flipCard();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                gradient: _showBack
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFFD4AF37),
                                          Color(0xFFAA7A1E),
                                        ],
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: _showBack
                                    ? [
                                        BoxShadow(
                                          color: const Color(
                                            0xFFD4AF37,
                                          ).withAlpha(80),
                                          blurRadius: 12,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.admin_panel_settings_rounded,
                                    size: 15,
                                    color: _showBack
                                        ? Colors.black87
                                        : Colors.white60,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Arxa Tərəf (Səlahiyyətlər)',
                                    style: TextStyle(
                                      color: _showBack
                                          ? Colors.black87
                                          : Colors.white60,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12.5,
                                    ),
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

                const SizedBox(height: 18),

                // 3D Flippable Teacher ID Card
                GestureDetector(
                  onTap: _flipCard,
                  child: AnimatedBuilder(
                    animation: _flipAnimation,
                    builder: (context, child) {
                      final angle = _flipAnimation.value * pi;
                      final isUnder = angle > (pi / 2);

                      return Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.0012)
                          ..rotateY(angle),
                        alignment: Alignment.center,
                        child: isUnder
                            ? Transform(
                                transform: Matrix4.identity()..rotateY(pi),
                                alignment: Alignment.center,
                                child: _buildCardBack(user, teacherClasses),
                              )
                            : _buildCardFront(user, teacherClasses),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 18),

                // Tap & Flip Hint Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withAlpha(12)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.screen_rotation_rounded,
                        color: Color(0xFFFFDF79),
                        size: 15,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Səlahiyyət və qeydlərə baxmaq üçün vəsiqəyə toxunun',
                        style: TextStyle(
                          color: Colors.white.withAlpha(180),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Quick Action Cards
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _triggerNfc,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF221E14), Color(0xFF131109)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: _isNfcActive
                                  ? const Color(0xFFD4AF37)
                                  : const Color(0xFFD4AF37).withAlpha(40),
                              width: _isNfcActive ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(60),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _isNfcActive
                                      ? const Color(0xFFD4AF37)
                                      : const Color(0xFFD4AF37).withAlpha(30),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.nfc_rounded,
                                  color: _isNfcActive
                                      ? Colors.black87
                                      : const Color(0xFFFFDF79),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Müəllim NFC',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isNfcActive ? 'Oxunur...' : 'Turniket & Otaq',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(140),
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showZoomedQrModal(
                          context,
                          teacherCode,
                          'Müəllim Təsdiq QR',
                          '$teacherName • $teacherPosition',
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF131A29), Color(0xFF0B101E)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withAlpha(15),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(60),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryAccent.withAlpha(30),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.qr_code_scanner_rounded,
                                  color: AppColors.primaryAccent,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'QR Skaner',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Böyük ekranda aç',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(140),
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Faculty Official Status Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1220),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withAlpha(40),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFFFFDF79),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Təsdiqlənmiş Pedaqoq Kimliyi',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF00E676),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Elektron jurnal, imtahan nəticələri və tədris sistemlərinə tam səlahiyyətli giriş.',
                              style: TextStyle(
                                color: Colors.white.withAlpha(160),
                                fontSize: 11,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // FRONT OF THE TEACHER CARD
  // ─────────────────────────────────────────────────────────────
  Widget _buildCardFront(AppUser? user, List<String> classes) {
    final teacherCode = user?.idrakCode ?? 'IDR-TCH-001';
    final teacherName = user?.fullName ?? 'Müəllim';
    final teacherPosition = user?.position ?? 'Pedaqoji Heyət / Fənn Müəllimi';

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 390),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF141724), Color(0xFF1E1F30), Color(0xFF10121D)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFD4AF37).withAlpha(180),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withAlpha(60),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(140),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Stack(
          children: [
            // Gold Holographic sheen
            _buildGoldSheen(),

            // Watermark Logo
            Positioned(
              right: -30,
              bottom: -30,
              child: Opacity(
                opacity: 0.04,
                child: const IdrakLogo(size: 200, showText: false),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header: Logo, Title, NFC Wave Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37).withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFD4AF37).withAlpha(40),
                              ),
                            ),
                            child: const IdrakLogo(size: 28),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'İDRAK LİSEYİ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(
                                'PEDAQOJİ HEYƏT VƏSİQƏSİ',
                                style: TextStyle(
                                  color: Color(0xFFFFDF79),
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.9,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withAlpha(15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.contactless_rounded,
                          color: Color(0xFFFFDF79),
                          size: 20,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // EMV Chip & Faculty Pass Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildGoldEmvChip(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFD4AF37), Color(0xFF8C6B1C)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withAlpha(80),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.workspace_premium_rounded,
                              color: Colors.black87,
                              size: 11,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'FACULTY PASS',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Photo + Teacher Details
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo Frame with Gold Glow
                      Container(
                        width: 76,
                        height: 92,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFFFDF79),
                            width: 1.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withAlpha(50),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                user?.photoUrl ?? '',
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  color: const Color(0xFF1E293B),
                                  child: const Icon(
                                    Icons.person_outline_rounded,
                                    color: Color(0xFFFFDF79),
                                    size: 38,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  color: Colors.black.withAlpha(180),
                                  child: const Text(
                                    'PEDAQOQ',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFFFFDF79),
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Details Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              teacherName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildCardField('İDRAK KODU', teacherCode),
                            const SizedBox(height: 4),
                            _buildCardField(
                              'VƏZİFƏ / KAFEDRA',
                              teacherPosition,
                            ),
                            if (user?.finCode != null &&
                                user!.finCode!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              _buildCardField('FIN KOD', user.finCode!),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Divider(color: Colors.white.withAlpha(20), height: 1),
                  const SizedBox(height: 10),

                  // Bottom QR & Classes Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TƏDRİS OLUNAN SİNİFLƏR',
                            style: TextStyle(
                              color: Color(0xFFFFDF79),
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            classes.isNotEmpty
                                ? classes.join(' • ')
                                : '9B • 10A • 11A',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => _showZoomedQrModal(
                          context,
                          teacherCode,
                          'Müəllim Turniket QR',
                          '$teacherName • $teacherCode',
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD4AF37).withAlpha(40),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: teacherCode,
                            version: QrVersions.auto,
                            size: 40,
                            padding: EdgeInsets.zero,
                          ),
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
    );
  }

  // ─────────────────────────────────────────────────────────────
  // BACK OF THE TEACHER CARD (PERMISSIONS & CONTRACT)
  // ─────────────────────────────────────────────────────────────
  Widget _buildCardBack(AppUser? user, List<String> classes) {
    final teacherCode = user?.idrakCode ?? 'IDR-TCH-001';
    final perms = user?.teacherPermissions;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 390),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF141724), Color(0xFF1E1F30), Color(0xFF10121D)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFD4AF37).withAlpha(180),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withAlpha(60),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(140),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Stack(
          children: [
            _buildGoldSheen(),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // High-gloss Magnetic Stripe with Gold Line
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  height: 42,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF0F0F0F),
                        Color(0xFF252118),
                        Color(0xFF0A0A0A),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            const Color(0xFFD4AF37).withAlpha(80),
                            const Color(0xFFFFDF79).withAlpha(120),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(
                                Icons.security_rounded,
                                color: Color(0xFFFFDF79),
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'SƏLAHİYYƏT VƏ İCAZƏ BAZASI',
                                style: TextStyle(
                                  color: Color(0xFFFFDF79),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10.5,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.success.withAlpha(50),
                              ),
                            ),
                            child: const Text(
                              'TAM İCAZƏLİ',
                              style: TextStyle(
                                color: Color(0xFF00E676),
                                fontWeight: FontWeight.w900,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Permissions Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withAlpha(20)),
                        ),
                        child: Column(
                          children: [
                            _buildBackRow(
                              '📚 Elektron Jurnal & Qiymətlər:',
                              'Aktiv (Tam İcazə)',
                            ),
                            const SizedBox(height: 5),
                            _buildBackRow(
                              '🏛️ Sinif İdarəsi:',
                              classes.isNotEmpty
                                  ? classes.join(', ')
                                  : 'Təyin edilib',
                            ),
                            const SizedBox(height: 5),
                            _buildBackRow(
                              '🍽️ Yeməkxana Menyu Nəzarəti:',
                              perms?.canManageCafeteria == true
                                  ? 'Aktiv'
                                  : 'Passiv',
                            ),
                            const SizedBox(height: 5),
                            _buildBackRow(
                              '🏥 Tibbi Qeyd İcazəsi:',
                              perms?.canManageMedical == true
                                  ? 'Aktiv'
                                  : 'Yalnız Baxış',
                            ),
                            const SizedBox(height: 5),
                            _buildBackRow(
                              '📦 İnventar & Texniki Müraciət:',
                              perms?.canManageInventory == true
                                  ? 'Aktiv'
                                  : 'Aktiv',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Disclaimer Text
                      Text(
                        'Bu rəqəmsal vəsiqə İdrak Liseyi pedaqoji heyətinə məxsusdur. İtirilmiş kart aşkar edildikdə lisey rəhbərliyinə təhvil verilməlidir.',
                        style: TextStyle(
                          color: Colors.white.withAlpha(130),
                          fontSize: 8.5,
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Digital Stamp & Token
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(8),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withAlpha(15)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'PEDAQOJİ İMZA VƏ TOKEN',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  teacherCode,
                                  style: const TextStyle(
                                    color: Color(0xFFFFDF79),
                                    fontSize: 9.5,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: const [
                                Icon(
                                  Icons.verified_rounded,
                                  color: Color(0xFFFFDF79),
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'FACULTY VERIFIED',
                                  style: TextStyle(
                                    color: Color(0xFFFFDF79),
                                    fontSize: 8.5,
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFFFDF79),
            fontSize: 7.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildBackRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFFFDF79),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGoldEmvChip() {
    return Container(
      width: 38,
      height: 28,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFEEA9), Color(0xFFD4AF37), Color(0xFF8C6B1C)],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFFEEA9), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withAlpha(60),
            blurRadius: 6,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 12,
            top: 0,
            bottom: 0,
            child: Container(width: 1, color: const Color(0xFF5E450E)),
          ),
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: Container(width: 1, color: const Color(0xFF5E450E)),
          ),
          Positioned(
            top: 9,
            left: 0,
            right: 0,
            child: Container(height: 1, color: const Color(0xFF5E450E)),
          ),
          Positioned(
            bottom: 9,
            left: 0,
            right: 0,
            child: Container(height: 1, color: const Color(0xFF5E450E)),
          ),
        ],
      ),
    );
  }

  Widget _buildGoldSheen() {
    return AnimatedBuilder(
      animation: _goldSheenController,
      builder: (context, child) {
        return Positioned.fill(
          child: Transform.rotate(
            angle: 0.3,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(
                    -2.0 + (_goldSheenController.value * 4.0),
                    -1.0,
                  ),
                  end: Alignment(
                    -1.0 + (_goldSheenController.value * 4.0),
                    1.0,
                  ),
                  colors: [
                    Colors.transparent,
                    const Color(0xFFD4AF37).withAlpha(15),
                    const Color(0xFFFFDF79).withAlpha(35),
                    Colors.white.withAlpha(45),
                    const Color(0xFFFFDF79).withAlpha(35),
                    const Color(0xFFD4AF37).withAlpha(15),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.2, 0.4, 0.5, 0.6, 0.8, 1.0],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
