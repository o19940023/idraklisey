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
import 'teacher_timetable_view_screen.dart'; // ✅ YENİ: View-only
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

    final teacherName = currentUser?.fullName ?? 'Müəllim';
    final teacherSubject = currentUser?.subject ?? 'Tədris Şöbəsi';
    final teacherRoom = currentUser?.roomNumber ?? 'Otaq 302';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Premium Gradient Header ──
            SliverAppBar(
              expandedHeight: 210,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: AppColors.primary,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0F1023),
                        Color(0xFF1A1B2E),
                        Color(0xFF2D1B69),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Subtle pattern overlay
                      Positioned(
                        right: -30,
                        top: 20,
                        child: Icon(
                          Icons.school_rounded,
                          size: 160,
                          color: Colors.white.withAlpha(8),
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
                                // Avatar with gold ring
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFD4A574), Color(0xFFF5DEB3), Color(0xFFD4A574)],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.gold.withAlpha(40),
                                        blurRadius: 16,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: ModernAvatar(
                                    imageUrl: currentUser?.photoUrl ?? 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400',
                                    name: teacherName,
                                    size: 60,
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
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppColors.gold.withAlpha(25),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: AppColors.gold.withAlpha(40)),
                                            ),
                                            child: const Text(
                                              'MÜƏLLİM',
                                              style: TextStyle(
                                                color: AppColors.goldLight,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 1.2,
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
                                          fontSize: 19,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryAccent.withAlpha(30),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              teacherSubject,
                                              style: TextStyle(
                                                color: Colors.white.withAlpha(210),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(Icons.door_back_door_outlined, size: 12, color: Colors.white.withAlpha(140)),
                                          const SizedBox(width: 3),
                                          Text(
                                            teacherRoom,
                                            style: TextStyle(
                                              color: Colors.white.withAlpha(140),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Admin təyin etdiyi siniflər
                                      if (currentUser?.assignedClasses.isNotEmpty == true) ...[
                                        const SizedBox(height: 7),
                                        Wrap(
                                          spacing: 5,
                                          runSpacing: 4,
                                          children: [
                                            for (final cls in currentUser!.assignedClasses)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withAlpha(22),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.white.withAlpha(50)),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.school_rounded, size: 11, color: AppColors.goldLight),
                                                    const SizedBox(width: 4),
                                                    Text(cls, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800)),
                                                  ],
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
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                              MaterialPageRoute(builder: (_) => const CreateAssignmentScreen()),
                            );
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(20),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.add_task_rounded, color: Colors.white, size: 24),
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
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Sinif və ya şagirdlərə fərdi dərs tapşırığı təyin edin',
                                        style: TextStyle(color: Colors.white.withAlpha(178), fontSize: 11.5),
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
                                  child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Digital ID Pass Banner ──
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.gold.withAlpha(50)),
                        boxShadow: AppShadows.sm,
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
                          borderRadius: BorderRadius.circular(18),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFD4A574), Color(0xFFB8860B)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.badge_rounded, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Rəqəmsal Müəllim Vəsiqəsi',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'NFC Turniket & 3D Vəsiqə',
                                        style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.gold.withAlpha(15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.qr_code_rounded, color: AppColors.goldDark, size: 18),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Section: Müəllim Alətləri ──
                    const SectionHeader(
                      title: 'Müəllim Alətləri',
                      subtitle: 'Tədris, qiymətləndirmə və şagird modulları',
                      padding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 14),

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

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateAssignmentScreen()),
          );
        },
        backgroundColor: AppColors.primaryAccent,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_task_rounded, color: Colors.white, size: 20),
        label: const Text(
          'Yeni Tapşırıq',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
  }
}
