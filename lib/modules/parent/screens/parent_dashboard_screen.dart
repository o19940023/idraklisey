import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/idrak_logo.dart';
import '../../../providers/app_state.dart';
import 'timetable_matrix_screen.dart';
import 'grades_analytics_screen.dart';
import 'attendance_calendar_screen.dart';
import 'medical_card_screen.dart';
import 'parent_tickets_screen.dart';
import '../../student/screens/cafeteria_menu_screen.dart';
import '../../admin/widgets/reorderable_module_grid.dart';

class ParentDashboardScreen extends StatelessWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final student = appState.student;
    final isDark = appState.isDarkMode;
    final parentHeaderBase = isDark
        ? const Color(0xFF0F172A)
        : const Color(0xFF132A25);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Keep the original collapsing header animation. Stretching its
            // background also prevents the scaffold color showing on pull-down.
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: false,
              stretch: true,
              // This is a nested header below MainScreen's app bar. It should
              // collapse fully instead of leaving an empty green toolbar.
              primary: false,
              toolbarHeight: 0,
              collapsedHeight: 0,
              elevation: 0,
              backgroundColor: parentHeaderBase,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground],
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              const Color(0xFF0F172A),
                              const Color(0xFF064E3B),
                              parentHeaderBase,
                            ]
                          : [
                              const Color(0xFF132A25),
                              const Color(0xFF0D5C4B),
                              parentHeaderBase,
                            ],
                    ),
                  ),
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 44,
                    bottom: 12,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF34D399),
                              Color(0xFF059669),
                              Color(0xFF10B981),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withAlpha(80),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 26,
                          backgroundImage: NetworkImage(student.photoUrl),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF10B981,
                                    ).withAlpha(35),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF34D399,
                                      ).withAlpha(50),
                                    ),
                                  ),
                                  child: const Text(
                                    'VALİDEYN KABİNETİ',
                                    style: TextStyle(
                                      color: Color(0xFF34D399),
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
                              'Övladınız: ${student.className} • ${student.studentNumber}',
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

            // Övlad keçidi (birdən çox uşaq varsa)
            if (appState.children.length > 1)
              SliverToBoxAdapter(
                child: Container(
                  color: parentHeaderBase,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.diversity_3_rounded,
                            color: Color(0xFF34D399),
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Övladlarınız (${appState.children.length}) — keçid üçün toxunun:',
                            style: TextStyle(
                              color: Colors.white.withAlpha(190),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 40,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: appState.children.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final child = appState.children[index];
                            final isActive = child.id == student.id;
                            return GestureDetector(
                              onTap: () => appState.setActiveChild(child.id),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                decoration: BoxDecoration(
                                  gradient: isActive
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFF059669),
                                            Color(0xFF10B981),
                                          ],
                                        )
                                      : null,
                                  color: !isActive
                                      ? Colors.white.withAlpha(18)
                                      : null,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isActive
                                        ? const Color(0xFF34D399)
                                        : Colors.white.withAlpha(40),
                                    width: isActive ? 1.5 : 1,
                                  ),
                                  boxShadow: isActive
                                      ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF10B981,
                                            ).withAlpha(80),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isActive
                                          ? Icons.child_care_rounded
                                          : Icons.child_care_outlined,
                                      size: 16,
                                      color: isActive
                                          ? Colors.white
                                          : Colors.white70,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${child.fullName.split(' ').first} • ${child.className}',
                                      style: TextStyle(
                                        color: isActive
                                            ? Colors.white
                                            : Colors.white.withAlpha(200),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 90),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Stats Bar
                    Row(
                      children: [
                        _buildParentStatCard(
                          'GPA Balı',
                          '${student.gpa}',
                          Icons.star_rounded,
                          const Color(0xFFF59E0B),
                        ),
                        const SizedBox(width: 10),
                        _buildParentStatCard(
                          'Davamiyyət',
                          '${student.attendanceRate}%',
                          Icons.check_circle_rounded,
                          const Color(0xFF10B981),
                        ),
                        const SizedBox(width: 10),
                        _buildParentStatCard(
                          'Qan Qrupu',
                          student.bloodGroup ?? '—',
                          Icons.favorite_rounded,
                          const Color(0xFFEF4444),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    const SectionHeader(
                      title: 'Nəzarət və İzləmə Modulları',
                      subtitle:
                          'Qiymətlər, davamiyyət, tibb və müəllim əlaqəsi',
                      padding: EdgeInsets.zero,
                    ),

                    const SizedBox(height: 12),

                    // 2-Column Grid for Parent Modules (Sürükle-Bırak)
                    ReorderableModuleGrid(
                      modules: appState.getOrderedModules(),
                      dynamicData: const {
                        'parent_timetable': 'Gündəlik dərslər',
                        'parent_grades': 'KSQ / BSQ dinamika',
                        'parent_attendance': 'Rəqəmsal təqvim',
                        'parent_medical': 'Allergiya & Peyvənd',
                        'parent_tickets': 'Məktəb & Psixoloq',
                        'parent_cafeteria': 'Günün nahar menyusu',
                      },
                      onReorder: (newOrder) {
                        appState.updateModuleOrder(newOrder);
                      },
                      onModuleTap: (moduleId, ctx) {
                        switch (moduleId) {
                          case 'parent_timetable':
                            Navigator.push(
                              ctx,
                              MaterialPageRoute(
                                builder: (_) => const TimetableMatrixScreen(),
                              ),
                            );
                            break;
                          case 'parent_grades':
                            Navigator.push(
                              ctx,
                              MaterialPageRoute(
                                builder: (_) => const GradesAnalyticsScreen(),
                              ),
                            );
                            break;
                          case 'parent_attendance':
                            Navigator.push(
                              ctx,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const AttendanceCalendarScreen(),
                              ),
                            );
                            break;
                          case 'parent_medical':
                            Navigator.push(
                              ctx,
                              MaterialPageRoute(
                                builder: (_) => const MedicalCardScreen(),
                              ),
                            );
                            break;
                          case 'parent_tickets':
                            Navigator.push(
                              ctx,
                              MaterialPageRoute(
                                builder: (_) => const ParentTicketsScreen(),
                              ),
                            );
                            break;
                          case 'parent_cafeteria':
                            Navigator.push(
                              ctx,
                              MaterialPageRoute(
                                builder: (_) => const CafeteriaMenuScreen(),
                              ),
                            );
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

  Widget _buildParentStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
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
