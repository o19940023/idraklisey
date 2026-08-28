import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/widgets/modern_avatar.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/idrak_logo.dart';
import '../../../providers/app_state.dart';
import 'digital_id_card_screen.dart';
import 'assignments_timeline_screen.dart';
import 'meet_idrak_screen.dart';
import 'library_screen.dart';
import 'cafeteria_menu_screen.dart';
import '../../parent/screens/timetable_matrix_screen.dart';
import '../../parent/screens/grades_analytics_screen.dart';
import '../../admin/widgets/reorderable_module_grid.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final student = appState.student;
    final isDark = appState.isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Modern Cyber-Indigo Header Bar
            SliverAppBar(
              expandedHeight: 140.0,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.primary,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              const Color(0xFF0F172A),
                              const Color(0xFF1E1B4B),
                              const Color(0xFF1E293B),
                            ]
                          : [
                              const Color(0xFF1A1B2E),
                              const Color(0xFF282566),
                              const Color(0xFF16182E),
                            ],
                    ),
                  ),
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 44, bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFA29BFE), Color(0xFF6C5CE7), Color(0xFF00CEC9)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6C5CE7).withAlpha(80),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: ModernAvatar(
                          imageUrl: student.photoUrl,
                          name: student.fullName,
                          size: 54,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const IdrakLogo(size: 14),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6C5CE7).withAlpha(35),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFA29BFE).withAlpha(40)),
                                  ),
                                  child: const Text(
                                    'ŞAGİRD PORTALI',
                                    style: TextStyle(
                                      color: Color(0xFFA29BFE),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.9,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              student.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Sinif: ${student.className} • No: ${student.studentNumber}',
                              style: TextStyle(
                                color: Colors.white.withAlpha(180),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Stats Chips Row
                    Row(
                      children: [
                        _buildQuickMetricCard(
                          title: 'GPA Balı',
                          value: '${student.gpa}',
                          icon: Icons.star_rounded,
                          color: const Color(0xFFF59E0B),
                          bgColor: const Color(0xFFFEF3C7),
                        ),
                        const SizedBox(width: 10),
                        _buildQuickMetricCard(
                          title: 'Davamiyyət',
                          value: '${student.attendanceRate}%',
                          icon: Icons.check_circle_rounded,
                          color: const Color(0xFF10B981),
                          bgColor: const Color(0xFFD1FAE5),
                        ),
                        const SizedBox(width: 10),
                        _buildQuickMetricCard(
                          title: 'Status',
                          value: 'Aktiv',
                          icon: Icons.verified_rounded,
                          color: const Color(0xFF6366F1),
                          bgColor: const Color(0xFFEEF2FF),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Modern Digital ID Pass Banner (VIP Card Style)
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF1E1B4B),
                            Color(0xFF13172E),
                            Color(0xFF0F172A),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFF6C5CE7).withAlpha(90), width: 1.4),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C5CE7).withAlpha(50),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const DigitalIdCardScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(22),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF6C5CE7), Color(0xFF4834D4)],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF6C5CE7).withAlpha(90),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.qr_code_scanner_rounded,
                                    color: Colors.white,
                                    size: 24,
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
                                            'Rəqəmsal Kimlik Vəsiqəsi',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14.5,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF00E676).withAlpha(25),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Text(
                                              '3D PASS',
                                              style: TextStyle(
                                                color: Color(0xFF00E676),
                                                fontSize: 8,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Turniket, yeməkxana və kitabxana üçün NFC/QR vəsiqə',
                                        style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(18),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withAlpha(30)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Text(
                                        'Bax',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 12),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    const SectionHeader(
                      title: 'Xidmətlər və Modullar',
                      subtitle: 'Gündəlik dərslər, tapşırıqlar və məktəb resursları',
                      padding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 12),

                    // Modern 2-Column Action Cards Grid (Sürükle-Bırak)
                    ReorderableModuleGrid(
                      modules: appState.getOrderedModules(),
                      dynamicData: const {
                        'student_timetable': 'Həftəlik dərslər',
                        'student_assignments': 'Kamera ilə təhvil',
                        'student_meet': 'Canlı dərs otağı',
                        'student_library': 'Dərsliklər & PDF',
                        'student_cafeteria': 'Günün nahar menyusu',
                        'student_id': 'Rəqəmsal ID kartı',
                        'student_grades': 'Qiymətlər & Reytinq',
                      },
                      onReorder: (newOrder) {
                        appState.updateModuleOrder(newOrder);
                      },
                      onModuleTap: (moduleId, ctx) {
                        switch (moduleId) {
                          case 'student_timetable':
                            Navigator.push(ctx, MaterialPageRoute(builder: (_) => const TimetableMatrixScreen()));
                            break;
                          case 'student_assignments':
                            Navigator.push(ctx, MaterialPageRoute(builder: (_) => const AssignmentsTimelineScreen()));
                            break;
                          case 'student_meet':
                            Navigator.push(ctx, MaterialPageRoute(builder: (_) => const MeetIdrakScreen()));
                            break;
                          case 'student_library':
                            Navigator.push(ctx, MaterialPageRoute(builder: (_) => const LibraryScreen()));
                            break;
                          case 'student_cafeteria':
                            Navigator.push(ctx, MaterialPageRoute(builder: (_) => const CafeteriaMenuScreen()));
                            break;
                          case 'student_id':
                            Navigator.push(ctx, MaterialPageRoute(builder: (_) => const DigitalIdCardScreen()));
                            break;
                          case 'student_grades':
                            Navigator.push(ctx, MaterialPageRoute(builder: (_) => const GradesAnalyticsScreen()));
                            break;
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder.withAlpha(70)),
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              title,
              style: TextStyle(
                fontSize: 10.5,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
