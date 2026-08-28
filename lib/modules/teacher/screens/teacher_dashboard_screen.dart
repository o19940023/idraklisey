import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/widgets/modern_avatar.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/idrak_logo.dart';
import '../../../providers/app_state.dart';
import 'quick_grading_screen.dart';
import 'qr_inventory_ticket_screen.dart';
import 'teacher_students_screen.dart';
import 'create_assignment_screen.dart';
import 'review_submissions_screen.dart';
import 'teacher_timetable_view_screen.dart';
import '../../student/screens/library_screen.dart';
import 'teacher_id_card_screen.dart';
import '../../student/screens/meet_idrak_screen.dart';
import '../../shared/screens/notifications_screen.dart';
import '../../admin/widgets/reorderable_module_grid.dart';

class TeacherDashboardScreen extends StatelessWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currentUser = appState.currentUser;
    final isDark = appState.isDarkMode;

    final teacherName = currentUser?.fullName ?? 'Müəllim';
    final teacherSubject = currentUser?.subject ?? 'Tədris Şöbəsi';
    final teacherRoom = currentUser?.roomNumber ?? 'Otaq 302';
    final assignedClasses = currentUser?.assignedClasses ?? [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Premium Royal Gold Gradient Header ──
            SliverAppBar(
              expandedHeight: 200,
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
                              const Color(0xFF1E1F30),
                              const Color(0xFF141724),
                            ]
                          : [
                              const Color(0xFF141724),
                              const Color(0xFF1E1F30),
                              const Color(0xFF0C0E17),
                            ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Subtle watermark logo
                      Positioned(
                        right: -30,
                        top: 20,
                        child: Icon(
                          Icons.school_rounded,
                          size: 160,
                          color: const Color(0xFFD4AF37).withAlpha(12),
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.only(left: 20, right: 20, top: 46, bottom: 14),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Avatar with luxury gold ring
                                Container(
                                  padding: const EdgeInsets.all(2.5),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFFDF79), Color(0xFFD4AF37), Color(0xFF8C6B1C)],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFD4AF37).withAlpha(60),
                                        blurRadius: 16,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: ModernAvatar(
                                    imageUrl: currentUser?.photoUrl ?? 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400',
                                    name: teacherName,
                                    size: 58,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const IdrakLogo(size: 14),
                                          const SizedBox(width: 6),
                                          Flexible(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [Color(0xFFD4AF37), Color(0xFFAA7A1E)],
                                                ),
                                                borderRadius: BorderRadius.circular(14),
                                              ),
                                              child: const Text(
                                                'MÜƏLLİM • PEDAQOJİ HEYƏT',
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 1.0,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        teacherName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.4,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFD4AF37).withAlpha(25),
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: const Color(0xFFD4AF37).withAlpha(40)),
                                              ),
                                              child: Text(
                                                teacherSubject,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Color(0xFFFFDF79),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(Icons.door_back_door_outlined, size: 12, color: Colors.white.withAlpha(140)),
                                          const SizedBox(width: 3),
                                          Flexible(
                                            child: Text(
                                              teacherRoom,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.white.withAlpha(140),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (assignedClasses.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 5,
                                          runSpacing: 4,
                                          children: [
                                            for (final cls in assignedClasses)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withAlpha(18),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: Colors.white.withAlpha(30)),
                                                ),
                                                child: Text(
                                                  cls,
                                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ],
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
                        _buildMetricChip(
                          title: 'Şagirdlər',
                          value: '${appState.students.length}',
                          icon: Icons.groups_rounded,
                          color: const Color(0xFF3B82F6),
                        ),
                        const SizedBox(width: 10),
                        _buildMetricChip(
                          title: 'Tapşırıqlar',
                          value: '${appState.currentTeacherAssignments.length}',
                          icon: Icons.assignment_turned_in_rounded,
                          color: const Color(0xFF8B5CF6),
                        ),
                        const SizedBox(width: 10),
                        _buildMetricChip(
                          title: 'E-Kitablar',
                          value: '${appState.books.length}',
                          icon: Icons.local_library_rounded,
                          color: const Color(0xFF10B981),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── VIP Digital Teacher ID Pass Card ──
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF221E14),
                            Color(0xFF18150D),
                            Color(0xFF100E08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFD4AF37).withAlpha(90), width: 1.4),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withAlpha(40),
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
                              MaterialPageRoute(builder: (_) => const TeacherIdCardScreen()),
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
                                      colors: [Color(0xFFD4AF37), Color(0xFFAA7A1E)],
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFD4AF37).withAlpha(80),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.badge_rounded, color: Colors.black87, size: 24),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              'Rəqəmsal Müəllim Vəsiqəsi',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: -0.2,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFD4AF37).withAlpha(25),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Text(
                                              '3D PASS',
                                              style: TextStyle(
                                                color: Color(0xFFFFDF79),
                                                fontSize: 8,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'NFC Turniket, otaq açarı və 3D səlahiyyət kartı',
                                        style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD4AF37).withAlpha(20),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFD4AF37).withAlpha(40)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Text(
                                        'Bax',
                                        style: TextStyle(
                                          color: Color(0xFFFFDF79),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(Icons.arrow_forward_rounded, color: Color(0xFFFFDF79), size: 12),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Quick Action: Create Assignment ──
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF4F46E5), Color(0xFF6C5CE7), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6C5CE7).withAlpha(45),
                            blurRadius: 18,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CreateAssignmentScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(20),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.add_task_rounded, color: Colors.white, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Yeni Tapşırıq Yarat',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Sinif və ya şagirdlərə fərdi dərs tapşırığı təyin edin',
                                        style: TextStyle(color: Colors.white.withAlpha(178), fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(20),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ── Section: Müəllim Alətləri ──
                    const SectionHeader(
                      title: 'Müəllim Alətləri',
                      subtitle: 'Tədris, qiymətləndirmə və şagird modulları',
                      padding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 12),

                    // ── 2-Column Grid of Tools (Sürükle-Bırak) ──
                    ReorderableModuleGrid(
                      modules: appState.getOrderedModules(),
                      dynamicData: {
                        'teacher_timetable': 'Baxış rejimi',
                        'teacher_meet': 'Canlı səsli dərs',
                        'teacher_students': '${appState.students.length} Şagird',
                        'teacher_assignments': '${appState.currentTeacherAssignments.length} Tapşırıq',
                        'teacher_grading': 'Voice-to-Text rəy',
                        'teacher_library': '${appState.books.length} Kitab',
                        'teacher_notifications': 'Sinif & Valideyn',
                        'teacher_inventory': 'QR inventar şikayəti',
                      },
                      onReorder: (newOrder) {
                        appState.updateModuleOrder(newOrder);
                      },
                      onModuleTap: (moduleId, ctx) {
                        switch (moduleId) {
                          case 'teacher_timetable':
                            Navigator.push(ctx, MaterialPageRoute(builder: (_) => const TeacherTimetableViewScreen()));
                            break;
                          case 'teacher_meet':
                            Navigator.push(ctx, MaterialPageRoute(builder: (_) => const MeetIdrakScreen()));
                            break;
                          case 'teacher_students':
                            Navigator.push(ctx, MaterialPageRoute(builder: (_) => const TeacherStudentsScreen()));
                            break;
                          case 'teacher_assignments':
                            Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ReviewSubmissionsScreen()));
                            break;
                          case 'teacher_grading':
                            Navigator.push(ctx, MaterialPageRoute(builder: (_) => const QuickGradingScreen()));
                            break;
                          case 'teacher_library':
                            Navigator.push(ctx, MaterialPageRoute(builder: (_) => const LibraryScreen(isTeacherView: true)));
                            break;
                          case 'teacher_notifications':
                            Navigator.push(ctx, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                            break;
                          case 'teacher_inventory':
                            Navigator.push(ctx, MaterialPageRoute(builder: (_) => const QrInventoryTicketScreen()));
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

  Widget _buildMetricChip({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
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
                color: color.withAlpha(20),
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
