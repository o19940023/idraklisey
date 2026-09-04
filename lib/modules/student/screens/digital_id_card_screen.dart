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
import '../../../l10n/app_localizations.dart';

class DigitalIdCardScreen extends StatefulWidget {
  const DigitalIdCardScreen({super.key});

  @override
  State<DigitalIdCardScreen> createState() => _DigitalIdCardScreenState();
}

class _DigitalIdCardScreenState extends State<DigitalIdCardScreen>
    with TickerProviderStateMixin {
  late AnimationController _flipController;
  late AnimationController _shimmerController;
  late AnimationController _nfcPulseController;

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

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat(reverse: true);

    _nfcPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    _shimmerController.dispose();
    _nfcPulseController.dispose();
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
    _nfcPulseController.forward(from: 0).then((_) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() => _isNfcActive = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white),
                  SizedBox(width: 10),
                  Text('NFC Turniket siqnalı göndərildi • Giriş Təsdiqləndi'),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      });
    });
  }

  void _showZoomedQrModal(BuildContext context, String data, String title, String subtitle) {
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
              color: const Color(0xFF0F172A).withAlpha(240),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(color: Colors.white.withAlpha(30)),
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
                  style: const TextStyle(color: Colors.white60, fontSize: 12.5),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryAccent.withAlpha(100),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withAlpha(20)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primaryAccent, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'ID: $data',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'monospace'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Turniket və yeməkxana skanerləri üçün ekran parlaqlığını artırın',
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
    final loc = AppLocalizations.of(context);
    final appState = Provider.of<AppState>(context);
    final student = appState.student;
    final medCard = appState.medicalCard;

    return Scaffold(
      backgroundColor: const Color(0xFF070913),
      appBar: AppBar(
        title: Text(
          loc.digitalIdCard,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5, letterSpacing: -0.2),
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
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Colors.white),
          ),
          onPressed: () => handleBackNavigation(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryAccent.withAlpha(25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primaryAccent.withAlpha(50)),
              ),
              child: const Icon(Icons.qr_code_rounded, color: AppColors.primaryAccent, size: 18),
            ),
            tooltip: 'Böyük QR Göstər',
            onPressed: () => _showZoomedQrModal(
              context,
              student.studentNumber,
              'Turniket & Giriş QR Kodu',
              '${student.fullName} • ${student.className}',
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Background ambient light gradients
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6C5CE7).withAlpha(45),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -40,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0984E3).withAlpha(35),
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
                // Segmented Switcher (Ön / Arxa Tərəf) with Glassmorphism
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
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 9),
                              decoration: BoxDecoration(
                                gradient: !_showBack
                                    ? const LinearGradient(
                                        colors: [Color(0xFF6C5CE7), Color(0xFF4834D4)],
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: !_showBack
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF6C5CE7).withAlpha(80),
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
                                    color: !_showBack ? Colors.white : Colors.white60,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Ön Tərəf',
                                    style: TextStyle(
                                      color: !_showBack ? Colors.white : Colors.white60,
                                      fontWeight: FontWeight.w800,
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
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 9),
                              decoration: BoxDecoration(
                                gradient: _showBack
                                    ? const LinearGradient(
                                        colors: [Color(0xFF6C5CE7), Color(0xFF4834D4)],
                                      )
                                    : null,
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: _showBack
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF6C5CE7).withAlpha(80),
                                          blurRadius: 12,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.medical_information_rounded,
                                    size: 15,
                                    color: _showBack ? Colors.white : Colors.white60,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${loc.medicalCard}',
                                    style: TextStyle(
                                      color: _showBack ? Colors.white : Colors.white60,
                                      fontWeight: FontWeight.w800,
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

                // 3D Animated Flip Card
                GestureDetector(
                  onTap: _flipCard,
                  child: AnimatedBuilder(
                    animation: _flipAnimation,
                    builder: (context, child) {
                      final angle = _flipAnimation.value * pi;
                      final isUnder = angle > pi / 2;

                      return Transform(
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.0012) // Realistic camera perspective
                          ..rotateY(angle),
                        alignment: Alignment.center,
                        child: isUnder
                            ? Transform(
                                transform: Matrix4.identity()..rotateY(pi),
                                alignment: Alignment.center,
                                child: _buildCardBack(context, student, medCard),
                              )
                            : _buildCardFront(context, student),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 18),

                // Tap & Flip Hint Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withAlpha(12)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.screen_rotation_rounded, color: AppColors.primaryAccent, size: 15),
                      const SizedBox(width: 8),
                      Text(
                        'Digər tərəfə baxmaq üçün vəsiqəyə toxunun',
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

                // Quick Action Cards (NFC, QR Zoom, Status)
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _triggerNfc,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF1E1B4B),
                                Color(0xFF13172E),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: _isNfcActive
                                  ? const Color(0xFF6C5CE7)
                                  : Colors.white.withAlpha(15),
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
                                      ? const Color(0xFF6C5CE7)
                                      : const Color(0xFF6C5CE7).withAlpha(30),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.nfc_rounded,
                                  color: _isNfcActive ? Colors.white : const Color(0xFFA29BFE),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'NFC Turniket',
                                style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _isNfcActive ? 'Oxunur...' : 'Toxundur & Keç',
                                style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 10.5),
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
                          student.studentNumber,
                          'Şagird Giriş QR',
                          '${student.fullName} • ${student.className}',
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF162033),
                                Color(0xFF0F172A),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white.withAlpha(15)),
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
                              Text(
                                loc.scanQrCode,
                                style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${loc.cafeteria} & ${loc.library}',
                                style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 10.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Live Security & Validity Status Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A).withAlpha(180),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withAlpha(15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.success.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.verified_user_rounded, color: AppColors.success, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${loc.active} ${loc.student}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Bu vəsiqə İdrak Liseyinin rəsmi elektron təhlükəsizlik bazasında qeydiyyatdadır.',
                              style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 11, height: 1.3),
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
  // FRONT OF THE STUDENT CARD
  // ─────────────────────────────────────────────────────────────
  Widget _buildCardFront(BuildContext context, dynamic student) {
    final loc = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 390),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF181829),
            Color(0xFF221F3D),
            Color(0xFF14142B),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF6C5CE7).withAlpha(140), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withAlpha(60),
            blurRadius: 28,
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
            // Holographic dynamic sheen
            _buildHologramSheen(),

            // Subtle Background Watermark Logo
            Positioned(
              right: -30,
              bottom: -30,
              child: Opacity(
                opacity: 0.05,
                child: const IdrakLogo(size: 200, showText: false),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header: Logo, Title, Contactless Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(15),
                              borderRadius: BorderRadius.circular(10),
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
                                'BEYNƏLXALQ TƏHSİL MƏKTƏBİ',
                                style: TextStyle(
                                  color: Color(0xFFA29BFE),
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
                          color: Colors.white.withAlpha(12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.contactless_rounded, color: Colors.white70, size: 20),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // EMV Chip & Student Pass Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildEmvChip(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C5CE7), Color(0xFF00CEC9)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6C5CE7).withAlpha(80),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.school_rounded, color: Colors.white, size: 11),
                            SizedBox(width: 4),
                            Text(
                              'STUDENT PASS',
                              style: TextStyle(
                                color: Colors.white,
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

                  // Photo + Student Details
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Photo Frame with Glow Border
                      Container(
                        width: 76,
                        height: 92,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFA29BFE), width: 1.8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6C5CE7).withAlpha(50),
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
                                student.photoUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFF1E293B),
                                  child: const Icon(Icons.person, color: Colors.white54, size: 38),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  color: Colors.black.withAlpha(160),
                                  child: Text(
                                    loc.active.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFF00E676),
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
                              student.fullName,
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
                            _buildCardField(loc.studentNumber.toUpperCase(), student.studentNumber),
                            const SizedBox(height: 4),
                            _buildCardField(loc.classLabel.toUpperCase(), student.className),
                            if (student.finCode != null && student.finCode!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              _buildCardField('FIN KOD', student.finCode!),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Divider(color: Colors.white.withAlpha(20), height: 1),
                  const SizedBox(height: 10),

                  // Bottom QR & Barcode Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TƏSDİQLƏNMİŞ ELEKTRON VƏSİQƏ',
                            style: TextStyle(
                              color: Color(0xFFA29BFE),
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Tədris İli: ${student.academicYear}',
                            style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 9.5),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => _showZoomedQrModal(
                          context,
                          student.studentNumber,
                          'Turniket QR Kodu',
                          '${student.fullName} • ${student.studentNumber}',
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withAlpha(30),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: student.studentNumber,
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
  // BACK OF THE STUDENT CARD (MEDICAL & CONTACTS)
  // ─────────────────────────────────────────────────────────────
  Widget _buildCardBack(BuildContext context, dynamic student, dynamic medCard) {
    final loc = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 390),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFF181829),
            Color(0xFF221F3D),
            Color(0xFF14142B),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF6C5CE7).withAlpha(140), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withAlpha(60),
            blurRadius: 28,
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
            _buildHologramSheen(),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // High-gloss Magnetic Stripe with rainbow shimmer
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
                        Color(0xFF232323),
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
                            Colors.purpleAccent.withAlpha(60),
                            Colors.cyanAccent.withAlpha(80),
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
                      // Header Row: Medical / Security Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.shield_outlined, color: Color(0xFFA29BFE), size: 16),
                              SizedBox(width: 6),
                              Text(
                                'TƏCİLİ ƏLAQƏ VƏ TİBBİ MƏLUMAT',
                                style: TextStyle(
                                  color: Color(0xFFA29BFE),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10.5,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withAlpha(25),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.danger.withAlpha(50)),
                            ),
                            child: Text(
                              medCard.bloodGroup,
                              style: const TextStyle(
                                color: Color(0xFFFF7675),
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Medical & Emergency Info Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withAlpha(20)),
                        ),
                        child: Column(
                          children: [
                            _buildBackRow('🩸 ${loc.bloodGroup}:', medCard.bloodGroup, isHighlight: true),
                            const SizedBox(height: 5),
                            _buildBackRow('👨‍👩‍👧 ${loc.parent}:', student.parentName),
                            const SizedBox(height: 5),
                            _buildBackRow('📞 ${loc.parent} ${loc.phone}:', student.parentPhone),
                            const SizedBox(height: 5),
                            _buildBackRow('🏢 Tədris Ocağı:', 'İdrak Liseyi, Bakı'),
                            if (medCard.allergies.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              _buildBackRow('⚠️ ${loc.allergies}:', medCard.allergies.join(', '), isAlert: true),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Disclaimer Text
                      Text(
                        'Bu rəqəmsal vəsiqə İdrak Liseyinin mülkiyyətidir. İtirilmiş kart aşkar edildikdə rəhbərliyə məlumat verilməsi xahiş olunur.',
                        style: TextStyle(color: Colors.white.withAlpha(130), fontSize: 8.5, height: 1.3),
                      ),

                      const SizedBox(height: 10),

                      // Digital Stamp & Barcode
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                                  'KRİPTOQRAFİK SERTİFİKAT',
                                  style: TextStyle(color: Colors.white38, fontSize: 7.5, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  student.id,
                                  style: const TextStyle(
                                    color: Color(0xFFA29BFE),
                                    fontSize: 9.5,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.lock_outline_rounded, color: AppColors.success, size: 14),
                                const SizedBox(width: 4),
                                const Text(
                                  'SSL VERIFIED',
                                  style: TextStyle(
                                    color: AppColors.success,
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
          style: TextStyle(
            color: const Color(0xFFA29BFE).withAlpha(180),
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

  Widget _buildBackRow(String title, String value, {bool isHighlight = false, bool isAlert = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isAlert ? const Color(0xFFFF7675) : Colors.white70,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isAlert
                  ? const Color(0xFFFF7675)
                  : (isHighlight ? const Color(0xFFA29BFE) : Colors.white),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmvChip() {
    return Container(
      width: 38,
      height: 28,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFDF79),
            Color(0xFFD4AF37),
            Color(0xFF996515),
          ],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFFDF79), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withAlpha(50),
            blurRadius: 6,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Micro lines on EMV chip
          Positioned(
            left: 12,
            top: 0,
            bottom: 0,
            child: Container(width: 1, color: const Color(0xFF7A5210)),
          ),
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: Container(width: 1, color: const Color(0xFF7A5210)),
          ),
          Positioned(
            top: 9,
            left: 0,
            right: 0,
            child: Container(height: 1, color: const Color(0xFF7A5210)),
          ),
          Positioned(
            bottom: 9,
            left: 0,
            right: 0,
            child: Container(height: 1, color: const Color(0xFF7A5210)),
          ),
        ],
      ),
    );
  }

  Widget _buildHologramSheen() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Positioned.fill(
          child: Transform.rotate(
            angle: 0.3,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(
                    -2.0 + (_shimmerController.value * 4.0),
                    -1.0,
                  ),
                  end: Alignment(
                    -1.0 + (_shimmerController.value * 4.0),
                    1.0,
                  ),
                  colors: [
                    Colors.transparent,
                    Colors.purpleAccent.withAlpha(20),
                    Colors.cyanAccent.withAlpha(35),
                    Colors.white.withAlpha(40),
                    Colors.cyanAccent.withAlpha(35),
                    Colors.purpleAccent.withAlpha(20),
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
