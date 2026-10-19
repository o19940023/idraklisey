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
  late AnimationController _sheenController;
  late AnimationController _pulseController;
  late AnimationController _radarController;

  late Animation<double> _flipAnimation;
  bool _showBack = false;
  bool _isNfcScanning = false;
  bool _isCardLocked = false;

  // 3D Tilt interactive state
  double _tiltX = 0.0;
  double _tiltY = 0.0;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _flipAnimation = CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOutCubicEmphasized,
    );

    _sheenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    _sheenController.dispose();
    _pulseController.dispose();
    _radarController.dispose();
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
      _tiltX = 0;
      _tiltY = 0;
    });
  }

  void _triggerNfc() {
    if (_isCardLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.lock_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text('Vəsiqə bloklanıb. Əvvəlcə kilidi açın.'),
            ],
          ),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
      return;
    }

    HapticFeedback.heavyImpact();
    setState(() => _isNfcScanning = true);
    _radarController.repeat();

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        _radarController.stop();
        _radarController.reset();
        setState(() => _isNfcScanning = false);
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'NFC Turniket Keçidi Uğurlu • Əsas Korpus Qapı 1 Açıldı',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
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
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 38),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1020).withAlpha(245),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: Border.all(color: Colors.white.withAlpha(25)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(160),
                  blurRadius: 30,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primaryAccent, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 13),
                ),
                const SizedBox(height: 24),
                // QR Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF38BDF8).withAlpha(80),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: data,
                    version: QrVersions.auto,
                    size: 210,
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 18),
                // Realistic Code-128 Barcode Simulation
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      CustomPaint(
                        size: const Size(220, 36),
                        painter: _BarcodePainter(data: data),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withAlpha(18)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.light_mode_rounded, color: Color(0xFFFBBF24), size: 15),
                      SizedBox(width: 8),
                      Text(
                        'Turniket skaneri üçün ekran parlaqlığını artırın',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInitialsFallback(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final initials = parts.isEmpty
        ? 'İ'
        : (parts.length == 1
            ? parts.first.substring(0, parts.first.length > 2 ? 2 : 1)
            : '${parts.first[0]}${parts.last[0]}')
            .toUpperCase();
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F2B5C), Color(0xFF1E1B4B)],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final appState = Provider.of<AppState>(context);
    final student = appState.student;
    final medCard = appState.medicalCard;

    return Scaffold(
      backgroundColor: const Color(0xFF050814),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.badge_rounded, color: Color(0xFF38BDF8), size: 19),
            const SizedBox(width: 8),
            Text(
              loc.digitalIdCard,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16.5,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withAlpha(20)),
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: Colors.white),
          ),
          onPressed: () => handleBackNavigation(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF38BDF8).withAlpha(60)),
              ),
              child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF38BDF8), size: 17),
            ),
            tooltip: 'Turniket QR Kodunu Aç',
            onPressed: () => _showZoomedQrModal(
              context,
              student.studentNumber,
              'Şagird Giriş & Turniket QR',
              '${student.fullName} • ${student.className}',
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // Ambient luxury background mesh glow
          Positioned(
            top: -50,
            left: -40,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1D4ED8).withAlpha(55),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: 120,
            right: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4338CA).withAlpha(45),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Column(
              children: [
                // ── Interactive Segmented Mode Switcher (Ön Tərəf / Arxa Tibbi Kart) ──
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(12),
                    borderRadius: BorderRadius.circular(26),
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
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8.5),
                          decoration: BoxDecoration(
                            gradient: !_showBack
                                ? const LinearGradient(
                                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: !_showBack
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF2563EB).withAlpha(90),
                                      blurRadius: 14,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.credit_card_rounded,
                                size: 14,
                                color: !_showBack ? Colors.white : Colors.white60,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Ön Tərəf (Vəsiqə)',
                                style: TextStyle(
                                  color: !_showBack ? Colors.white : Colors.white60,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
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
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8.5),
                          decoration: BoxDecoration(
                            gradient: _showBack
                                ? const LinearGradient(
                                    colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: _showBack
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFDC2626).withAlpha(90),
                                      blurRadius: 14,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.medical_services_rounded,
                                size: 14,
                                color: _showBack ? Colors.white : Colors.white60,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Arxa Tərəf (${loc.medicalCard})',
                                style: TextStyle(
                                  color: _showBack ? Colors.white : Colors.white60,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ── 3D Realistic Interactive Tilt & Flip Card ──
                GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _tiltY = (_tiltY + details.delta.dx * 0.0018).clamp(-0.25, 0.25);
                      _tiltX = (_tiltX - details.delta.dy * 0.0018).clamp(-0.25, 0.25);
                    });
                  },
                  onPanEnd: (_) {
                    setState(() {
                      _tiltX = 0;
                      _tiltY = 0;
                    });
                  },
                  onTap: _flipCard,
                  child: AnimatedBuilder(
                    animation: _flipAnimation,
                    builder: (context, child) {
                      final flipValue = _flipAnimation.value * pi;
                      final isUnder = flipValue > (pi / 2);

                      final transform = Matrix4.identity()
                        ..setEntry(3, 2, 0.0011)
                        ..rotateX(_tiltX)
                        ..rotateY(flipValue + _tiltY);

                      return Transform(
                        transform: transform,
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

                const SizedBox(height: 14),

                // Interactive Hint Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(10),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withAlpha(14)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.touch_app_rounded, color: Color(0xFF38BDF8), size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'Çevirmək üçün toxunun • 3D perspektiv üçün sürüşdürün',
                            style: TextStyle(
                              color: Colors.white.withAlpha(170),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Interactive NFC Turniket Radar Button ──
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _isNfcScanning
                          ? [const Color(0xFF1E3A8A), const Color(0xFF1E1B4B)]
                          : [const Color(0xFF111827), const Color(0xFF0F172A)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: _isNfcScanning
                          ? const Color(0xFF38BDF8)
                          : Colors.white.withAlpha(20),
                      width: _isNfcScanning ? 1.6 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isNfcScanning
                            ? const Color(0xFF2563EB).withAlpha(80)
                            : Colors.black.withAlpha(80),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: _triggerNfc,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        child: Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                if (_isNfcScanning)
                                  AnimatedBuilder(
                                    animation: _radarController,
                                    builder: (context, _) {
                                      final v = _radarController.value;
                                      return Container(
                                        width: 52 + (v * 24),
                                        height: 52 + (v * 24),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(0xFF38BDF8).withAlpha(((1 - v) * 255).toInt().clamp(0, 255)),
                                            width: 2,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF2563EB), Color(0xFF0284C7)],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF2563EB).withAlpha(90),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.nfc_rounded, color: Colors.white, size: 26),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        _isNfcScanning ? 'Turniketə Toxundurulur...' : 'NFC Turniket Keçidi',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF10B981).withAlpha(25),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFF10B981).withAlpha(60)),
                                        ),
                                        child: const Text(
                                          'CANLI',
                                          style: TextStyle(
                                            color: Color(0xFF34D399),
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _isNfcScanning
                                        ? 'Turniket sensoruna yaxınlaşdırın...'
                                        : 'Toxundur & dərhal keç • Məktəb turniketi və yeməkxana',
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(160),
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF38BDF8).withAlpha(20),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFF38BDF8).withAlpha(50)),
                              ),
                              child: Text(
                                _isNfcScanning ? 'Oxunur' : 'Aktivləşdir',
                                style: const TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Quick Access Module Grid (Yeməkxana, Kitabxana, Servis) ──
                Row(
                  children: [
                    Expanded(
                      child: _buildPassServiceTile(
                        icon: Icons.restaurant_rounded,
                        color: const Color(0xFFF59E0B),
                        title: 'Yeməkxana',
                        subtitle: 'Rasion & Giriş',
                        badge: 'Aktiv',
                        onTap: () => _showZoomedQrModal(
                          context,
                          student.studentNumber,
                          'Yeməkxana Giriş QR',
                          '${student.fullName} • Günlük Rasion',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildPassServiceTile(
                        icon: Icons.local_library_rounded,
                        color: const Color(0xFF8B5CF6),
                        title: 'Kitabxana',
                        subtitle: 'Oxucu Bileti',
                        badge: 'VIP',
                        onTap: () => _showZoomedQrModal(
                          context,
                          student.studentNumber,
                          'Kitabxana Oxucu Passı',
                          '${student.fullName} • İdrak Elektron Fondu',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildPassServiceTile(
                        icon: Icons.directions_bus_rounded,
                        color: const Color(0xFF06B6D4),
                        title: 'Nəqliyyat',
                        subtitle: 'Servis Qeydiyyatı',
                        badge: 'Xətt 4',
                        onTap: () => _showZoomedQrModal(
                          context,
                          student.studentNumber,
                          'Məktəb Avtobus Bileti',
                          '${student.fullName} • Avtobus №4',
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Live Security & Control Panel ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0C1322),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withAlpha(16)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: (_isCardLocked ? AppColors.danger : AppColors.success).withAlpha(20),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _isCardLocked ? Icons.lock_rounded : Icons.verified_user_rounded,
                                  color: _isCardLocked ? AppColors.danger : AppColors.success,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isCardLocked ? 'Vəsiqə Müvəqqəti Donub' : 'Təsdiqlənmiş Tələbə Kimliyi',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _isCardLocked
                                        ? 'Turniket və yeməkxana keçidləri dayandırılıb'
                                        : 'Təhlükəsizlik bazasında tam qeydiyyatdadır',
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(140),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Switch.adaptive(
                            value: !_isCardLocked,
                            activeTrackColor: AppColors.success,
                            onChanged: (val) {
                              HapticFeedback.selectionClick();
                              setState(() => _isCardLocked = !val);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Divider(color: Colors.white.withAlpha(15), height: 1),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSecurityInfoItem('Şifrləmə', 'AES-256 GCM'),
                          _buildSecurityInfoItem('Protokol', 'NFC ISO 14443A'),
                          _buildSecurityInfoItem('Son Keçid', '08:35 • Qapı 1'),
                        ],
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
  // FRONT OF THE STUDENT CARD (ULTRA LUXURY BESPOKE DESIGN)
  // ─────────────────────────────────────────────────────────────
  Widget _buildCardFront(BuildContext context, dynamic student) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 395),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
            Color(0xFF090D1A),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF38BDF8).withAlpha(180), width: 1.6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withAlpha(80),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(180),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Stack(
          children: [
            // Guilloche Geometric Security Pattern custom drawn
            Positioned.fill(
              child: CustomPaint(
                painter: _GuillocheSecurityPainter(accentColor: const Color(0xFF38BDF8)),
              ),
            ),

            // Dynamic Hologram Sheen
            _buildHologramSheen(),

            // Watermark Big Logo
            Positioned(
              right: -35,
              bottom: -35,
              child: Opacity(
                opacity: 0.045,
                child: const IdrakLogo(size: 220, showText: false),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top Header: Logo + Micro Security String + Contactless ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white.withAlpha(25)),
                            ),
                            child: const IdrakLogo(size: 26),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'İDRAK LİSEYİ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.4,
                                ),
                              ),
                              Text(
                                'OFFICIAL STUDENT CREDENTIAL',
                                style: TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Hologram Foil Seal
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF38BDF8), Color(0xFFA855F7), Color(0xFFF43F5E)],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'VERIFIED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 7.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.contactless_rounded, color: Colors.white70, size: 20),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ── EMV Microchip + Pass Type Pill ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildEmvMicrochip(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1E40AF), Color(0xFF0369A1)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF38BDF8).withAlpha(120)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF38BDF8).withAlpha(60),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.school_rounded, color: Colors.white, size: 11),
                            SizedBox(width: 4),
                            Text(
                              'STUDENT VIP PASS',
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

                  // ── Student Portrait + Details ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // High-fashion Portrait Frame with Dual-ring Aura
                      Container(
                        width: 78,
                        height: 94,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: const Color(0xFF38BDF8), width: 1.8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF38BDF8).withAlpha(60),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (student.photoUrl.trim().isNotEmpty)
                                Image.network(
                                  student.photoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => _buildInitialsFallback(student.fullName),
                                )
                              else
                                _buildInitialsFallback(student.fullName),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(200),
                                  ),
                                  child: const Text(
                                    'AKTİV ŞAGİRD',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF34D399),
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

                      // Laser-engraved Student Name and Data Fields
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
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                                shadows: [
                                  Shadow(
                                    color: Colors.black87,
                                    blurRadius: 4,
                                    offset: Offset(0, 1.5),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 7),
                            _buildEmbossedField('ŞAGİRD KODU', student.studentNumber),
                            const SizedBox(height: 4),
                            _buildEmbossedField('SİNİF / TƏDRİS', student.className),
                            if (student.finCode != null && student.finCode!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              _buildEmbossedField('FİN KOD', student.finCode!),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  Divider(color: Colors.white.withAlpha(22), height: 1),
                  const SizedBox(height: 10),

                  // ── Realistic Code128 Barcode + Fast Turniket QR ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomPaint(
                            size: const Size(130, 22),
                            painter: _BarcodePainter(data: student.studentNumber, isDark: false),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Tədris İli: ${student.academicYear}',
                            style: TextStyle(
                              color: Colors.white.withAlpha(160),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => _showZoomedQrModal(
                          context,
                          student.studentNumber,
                          'Turniket Giriş QR',
                          '${student.fullName} • ${student.studentNumber}',
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withAlpha(50),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: student.studentNumber,
                            version: QrVersions.auto,
                            size: 38,
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
  // BACK OF THE STUDENT CARD (MEDICAL, GUARDIAN & SECURITY PASS)
  // ─────────────────────────────────────────────────────────────
  Widget _buildCardBack(BuildContext context, dynamic student, dynamic medCard) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 395),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
            Color(0xFF080C14),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEF4444).withAlpha(160), width: 1.6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withAlpha(60),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withAlpha(180),
            blurRadius: 20,
            offset: const Offset(0, 10),
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
                // High-Coercivity Magnetic Stripe with Holographic Ribbon
                Container(
                  margin: const EdgeInsets.only(top: 14),
                  height: 42,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF080808),
                        Color(0xFF1C1C1C),
                        Color(0xFF050505),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      height: 5,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Color(0xFFEC4899),
                            Color(0xFF38BDF8),
                            Color(0xFF10B981),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Emergency & Blood Group Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.health_and_safety_rounded, color: Color(0xFFEF4444), size: 17),
                              SizedBox(width: 6),
                              Text(
                                'TƏCİLİ TİBBİ MƏLUMAT VƏ ƏLAQƏ',
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFDC2626).withAlpha(80),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Text(
                              'QAN: ${medCard.bloodGroup}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Medical Details Glass Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withAlpha(18)),
                        ),
                        child: Column(
                          children: [
                            _buildBackInfoRow('🩸 Qan Qrupu:', medCard.bloodGroup, isHighlight: true),
                            const SizedBox(height: 5),
                            _buildBackInfoRow('👨‍👩‍👧 Valideyn:', student.parentName),
                            const SizedBox(height: 5),
                            _buildBackInfoRow('📞 Təcili Əlaqə:', student.parentPhone),
                            const SizedBox(height: 5),
                            _buildBackInfoRow('🏢 Təhsil Müəssisəsi:', 'İdrak Liseyi, Bakı'),
                            if (medCard.allergies.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              _buildBackInfoRow('⚠️ Allergiya / Qeyd:', medCard.allergies.join(', '), isAlert: true),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Institutional Ownership Disclaimer
                      Text(
                        'Bu rəqəmsal vəsiqə İdrak Liseyinin mülkiyyətidir. Aşkar edildikdə məktəb müdiriyyətinə və ya təhlükəsizlik xidmətinə təhvil verilməlidir.',
                        style: TextStyle(color: Colors.white.withAlpha(130), fontSize: 8.5, height: 1.3),
                      ),

                      const SizedBox(height: 8),

                      // Cryptographic SSL Security Strip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(8),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withAlpha(14)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'KRİPTOQRAFİK AUDİT KODU',
                                  style: TextStyle(color: Colors.white38, fontSize: 7, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  student.id,
                                  style: const TextStyle(
                                    color: Color(0xFF38BDF8),
                                    fontSize: 9.5,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: const [
                                Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'SHA-256 SECURED',
                                  style: TextStyle(
                                    color: Color(0xFF10B981),
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

  Widget _buildEmbossedField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF38BDF8).withAlpha(190),
            fontSize: 7.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  Widget _buildBackInfoRow(String title, String value, {bool isHighlight = false, bool isAlert = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isAlert ? const Color(0xFFF87171) : Colors.white70,
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
                  ? const Color(0xFFF87171)
                  : (isHighlight ? const Color(0xFF38BDF8) : Colors.white),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmvMicrochip() {
    return Container(
      width: 40,
      height: 29,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFDF79),
            Color(0xFFD4AF37),
            Color(0xFF8A5A12),
          ],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFFDF79), width: 0.9),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withAlpha(70),
            blurRadius: 8,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 13,
            top: 0,
            bottom: 0,
            child: Container(width: 1, color: const Color(0xFF6B450C)),
          ),
          Positioned(
            right: 13,
            top: 0,
            bottom: 0,
            child: Container(width: 1, color: const Color(0xFF6B450C)),
          ),
          Positioned(
            top: 9,
            left: 0,
            right: 0,
            child: Container(height: 1, color: const Color(0xFF6B450C)),
          ),
          Positioned(
            bottom: 9,
            left: 0,
            right: 0,
            child: Container(height: 1, color: const Color(0xFF6B450C)),
          ),
          Center(
            child: Container(
              width: 10,
              height: 7,
              decoration: BoxDecoration(
                color: const Color(0xFFB47C1C),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHologramSheen() {
    return AnimatedBuilder(
      animation: _sheenController,
      builder: (context, child) {
        return Positioned.fill(
          child: Transform.rotate(
            angle: 0.35,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-2.2 + (_sheenController.value * 4.4), -1.0),
                  end: Alignment(-1.2 + (_sheenController.value * 4.4), 1.0),
                  colors: [
                    Colors.transparent,
                    Colors.purpleAccent.withAlpha(20),
                    const Color(0xFF38BDF8).withAlpha(45),
                    Colors.white.withAlpha(55),
                    const Color(0xFF38BDF8).withAlpha(45),
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

  Widget _buildPassServiceTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withAlpha(14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: color.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 1),
            Text(
              subtitle,
              style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 9.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityInfoItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: Colors.white.withAlpha(140), fontSize: 9.5),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// GUILLOCHE ANTI-COUNTERFEIT SECURITY PAINTER
// ─────────────────────────────────────────────────────────────
class _GuillocheSecurityPainter extends CustomPainter {
  final Color accentColor;
  _GuillocheSecurityPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accentColor.withAlpha(16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final path = Path();
    const steps = 14;
    for (int i = 0; i < steps; i++) {
      final yOffset = (size.height / steps) * i;
      path.moveTo(0, yOffset);
      for (double x = 0; x <= size.width; x += 10) {
        final y = yOffset + sin((x / size.width) * 2 * pi + (i * 0.4)) * 8;
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────
// CODE-128 BARCODE VECTOR PAINTER
// ─────────────────────────────────────────────────────────────
class _BarcodePainter extends CustomPainter {
  final String data;
  final bool isDark;

  _BarcodePainter({required this.data, this.isDark = true});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark ? Colors.black87 : Colors.white.withAlpha(200)
      ..style = PaintingStyle.fill;

    final random = Random(data.hashCode);
    double currentX = 0;
    while (currentX < size.width) {
      final barWidth = (random.nextInt(3) + 1.2);
      final spaceWidth = (random.nextInt(2) + 1.0);
      if (currentX + barWidth <= size.width) {
        canvas.drawRect(Rect.fromLTWH(currentX, 0, barWidth, size.height), paint);
      }
      currentX += barWidth + spaceWidth;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
