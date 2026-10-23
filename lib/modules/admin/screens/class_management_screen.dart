import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/modern_avatar.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/app_state.dart';

class ClassManagementScreen extends StatefulWidget {
  const ClassManagementScreen({super.key});

  @override
  State<ClassManagementScreen> createState() => _ClassManagementScreenState();
}

class _ClassManagementScreenState extends State<ClassManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final palette = AppPalette.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final classes = [...appState.allDistinctClasses]..sort();
    final totalStudents = appState.students.length;
    final subtitle = '${classes.length} sinif • $totalStudents şagird';

    return Scaffold(
      backgroundColor: palette.bgBase,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: palette.brandRoyal,
        foregroundColor: Colors.white,
        onPressed: () => _showCreateClassSheet(context, palette, appState),
        icon: const Icon(Icons.add_rounded, size: 19),
        label: const Text(
          'Yeni sinif',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildHeader(context, palette, subtitle),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildOverview(palette, appState, classes.length, totalStudents),
            ),
          ),
          if (classes.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _buildEmptyState(
                context,
                palette,
                icon: Icons.class_outlined,
                title: 'Hələ sinif yaradılmayıb',
                message:
                    'Aşağıdakı düymə ilə ilk sinifi əlavə edin — şagirdlər və müəllimləri oraya təyin edə bilərsiniz.',
              ),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Text(
                      'Siniflər',
                      style: AppTypography.title1(context).copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: palette.brandRoyal.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${classes.length}',
                        style: TextStyle(
                          color: palette.brandRoyal,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildClassCard(
                    context,
                    palette,
                    colorScheme,
                    appState,
                    classes[index],
                  ),
                  childCount: classes.length,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppPalette palette,
    String subtitle,
  ) {
    return SliverAppBar(
      expandedHeight: 132,
      pinned: true,
      elevation: 0,
      backgroundColor: palette.brandNavy,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: LayoutBuilder(
          builder: (context, constraints) {
            final showContent = constraints.maxHeight >= 96;
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF07152B),
                    Color(0xFF132C5E),
                    Color(0xFF2563EB),
                  ],
                ),
              ),
              child: !showContent
                  ? const SizedBox.expand()
                  : Stack(
                      children: [
                        Positioned(
                          right: -34,
                          top: -40,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                        ),
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 44, 20, 16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.14),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.class_rounded,
                                        size: 22,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Sinif İdarəsi',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          subtitle,
                                          style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.72),
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOverview(AppPalette palette, AppState appState, int classCount, int students) {
    final gpas = appState.students
        .where((student) => student.gpa > 0)
        .map((student) => student.gpa)
        .toList();
    final averageGpa = gpas.isEmpty
        ? 0.0
        : gpas.reduce((a, b) => a + b) / gpas.length;

    return StatCardRow(
      columns: 3,
      spacing: 8,
      children: [
        StatCard(
          value: '$classCount',
          label: 'Sinif',
          icon: Icons.class_rounded,
          color: palette.brandRoyal,
          compact: true,
        ),
        StatCard(
          value: '$students',
          label: 'Şagird',
          icon: Icons.people_alt_rounded,
          color: const Color(0xFF0D9488),
          compact: true,
        ),
        StatCard(
          value: gpas.isEmpty ? '—' : averageGpa.toStringAsFixed(2),
          label: 'Orta GPA',
          icon: Icons.auto_graph_rounded,
          color: palette.brandGold,
          compact: true,
        ),
      ],
    );
  }

  Widget _buildClassCard(
    BuildContext context,
    AppPalette palette,
    ColorScheme colorScheme,
    AppState appState,
    String className,
  ) {
    final students = appState.getStudentsForClass(className);
    final teachers = appState.users
        .where(
          (user) =>
              user.role == UserRole.teacher &&
              user.assignedClasses.contains(className),
        )
        .toList();
    final details = appState.classDetails(className);
    final infoLine = <String>[
      if ((details?.room ?? '').isNotEmpty) 'Otaq ${details!.room}',
      if ((details?.academicYear ?? '').isNotEmpty) details!.academicYear,
    ].join(' • ');

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(13, 12, 8, 12),
      borderRadius: 18,
      onTap: () =>
          _openClassDetailsSheet(context, appState, palette, className),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: palette.brandRoyal.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: palette.brandRoyal.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              className,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: palette.brandRoyal,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${students.length} şagird • ${teachers.length} müəllim',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  infoLine.isEmpty ? 'Detallar əlavə edilməyib' : infoLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: palette.textMuted,
          ),
        ],
      ),
    );
  }

  void _openClassDetailsSheet(
    BuildContext context,
    AppState appState,
    AppPalette palette,
    String className,
  ) {
    showAppSheet(
      context,
      maxHeight: MediaQuery.sizeOf(context).height * 0.86,
      builder: (sheetContext) {
        final appState = sheetContext.watch<AppState>();
        final palette = AppPalette.of(sheetContext);
        final colorScheme = Theme.of(sheetContext).colorScheme;
        final students = appState.getStudentsForClass(className);
        final teachers = appState.users
            .where(
              (user) =>
                  user.role == UserRole.teacher &&
                  user.assignedClasses.contains(className),
            )
            .toList();
        final details = appState.classDetails(className);
        final curatorUsers = details?.curatorTeacherId == null
            ? null
            : appState.users
                .where((user) => user.id == details!.curatorTeacherId)
                .toList();
        final curator = (curatorUsers == null || curatorUsers.isEmpty)
            ? null
            : curatorUsers.first;
        final avgGpa = appState.getClassAverageGpa(className);
        final avgAttendance = appState.getClassAverageAttendance(className);

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: palette.brandRoyal.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: palette.brandRoyal.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      className,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: palette.brandRoyal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      students.isEmpty
                          ? 'Şagird əlavə edilməyib'
                          : '${students.length} şagird',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sinifi yüksəlt',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => _showPromoteClassDialog(
                      sheetContext,
                      appState,
                      className,
                    ),
                    icon: Icon(
                      Icons.upgrade_rounded,
                      size: 19,
                      color: palette.brandRoyal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildMiniStat(
                      context,
                      label: 'Orta GPA',
                      value: avgGpa > 0
                          ? avgGpa.toStringAsFixed(2)
                          : 'Yoxdur',
                      icon: Icons.auto_graph_rounded,
                      color: palette.brandRoyal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMiniStat(
                      context,
                      label: 'Davamiyyət',
                      value: avgAttendance > 0
                          ? '$avgAttendance%'
                          : 'Yeni',
                      icon: Icons.fact_check_rounded,
                      color: const Color(0xFF0D9488),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMiniStat(
                      context,
                      label: 'Müəllim',
                      value: '${teachers.length}',
                      icon: Icons.person_rounded,
                      color: palette.brandGold,
                    ),
                  ),
                ],
              ),
              if (details != null &&
                  ((details.room ?? '').isNotEmpty ||
                      curator != null ||
                      (details.academicYear).isNotEmpty ||
                      (details.note ?? '').isNotEmpty)) ...[
                const SizedBox(height: 16),
                _buildInfoTile(
                  colorScheme,
                  icon: Icons.meeting_room_rounded,
                  text: 'Otaq: ${details.room}',
                  visible: (details.room ?? '').isNotEmpty,
                ),
                _buildInfoTile(
                  colorScheme,
                  icon: Icons.person_rounded,
                  text: 'Sinif rəhbəri: ${curator?.fullName}',
                  visible: curator != null,
                ),
                _buildInfoTile(
                  colorScheme,
                  icon: Icons.calendar_today_rounded,
                  text: 'Təhsil ili: ${details.academicYear}',
                  visible: details.academicYear.isNotEmpty,
                ),
                _buildInfoTile(
                  colorScheme,
                  icon: Icons.notes_rounded,
                  text: details.note ?? '',
                  visible: (details.note ?? '').isNotEmpty,
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Müəllimlər',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final teacher in teachers)
                    GestureDetector(
                      onTap: () => _showTeacherDetailSheet(
                        sheetContext,
                        appState,
                        teacher,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0D9488)
                              .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF0D9488)
                                .withValues(alpha: 0.22),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.person_rounded,
                              size: 14,
                              color: Color(0xFF0D9488),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${teacher.fullName}${teacher.subject != null && teacher.subject!.isNotEmpty ? " • ${teacher.subject}" : ""}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0D9488),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: () =>
                        _showAssignTeacherDialog(sheetContext, appState, className),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: palette.brandRoyal.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_add_alt_rounded,
                            size: 14,
                            color: palette.brandRoyal,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Müəllim təyin et',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: palette.brandRoyal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Şagirdlər (${students.length})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              if (students.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: palette.borderHairline,
                    ),
                  ),
                  child: Text(
                    'Bu sinifə hələ şagird təyin edilməyib.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ...students.map((student) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        ModernAvatar(
                          imageUrl: student.photoUrl,
                          name: student.fullName,
                          size: 38,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'ID: ${student.studentNumber} • Valideyn: ${student.parentName}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: student.gpa > 0
                                ? palette.brandRoyal.withValues(alpha: 0.09)
                                : palette.surface3,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            student.gpa > 0
                                ? 'GPA ${student.gpa.toStringAsFixed(2)}'
                                : 'Yeni',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: student.gpa > 0
                                  ? palette.brandRoyal
                                  : palette.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniStat(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(
    ColorScheme colorScheme, {
    required IconData icon,
    required String text,
    bool visible = true,
  }) {
    if (!visible) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppPalette palette, {
    required IconData icon,
    required String title,
    required String message,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: palette.brandRoyal.withValues(alpha: 0.07),
                shape: BoxShape.circle,
                border: Border.all(
                  color: palette.brandRoyal.withValues(alpha: 0.12),
                ),
              ),
              child: Icon(icon, size: 34, color: palette.brandRoyal),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Müəllim chipinə basılanda: bütün detalları — fənn, otaq, təyin olunan
  /// siniflər, əlaqə məlumatları
  void _showTeacherDetailSheet(
    BuildContext sheetContext,
    AppState appState,
    AppUser teacher,
  ) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    showAppSheet(
      sheetContext,
      maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75,
      builder: (ctx) {
        final palette = AppPalette.of(ctx);
        final colorScheme = Theme.of(ctx).colorScheme;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ModernAvatar(
                    imageUrl: teacher.photoUrl,
                    name: teacher.fullName,
                    size: 58,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teacher.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: colorScheme.onSurface,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Fənn: ${teacher.subject ?? 'Təyin edilməyib'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: palette.brandRoyal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _teacherDetailBox(
                ctx,
                palette,
                icon: Icons.school_rounded,
                title:
                    'Təyin Olunan Siniflər (${teacher.assignedClasses.length})',
                color: const Color(0xFF0D9488),
                children: teacher.assignedClasses.isEmpty
                    ? [
                        Text(
                          'Hələ sinif təyin edilməyib',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ]
                    : [
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final cls in teacher.assignedClasses)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D9488)
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(
                                    color: const Color(0xFF0D9488)
                                        .withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Text(
                                  cls,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0D9488),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
              ),
              const SizedBox(height: 12),
              _teacherDetailBox(
                ctx,
                palette,
                icon: Icons.badge_rounded,
                title: 'Şəxsi Məlumatlar',
                color: palette.brandRoyal,
                children: [
                  if (teacher.fatherName != null)
                    _teacherInfoRow(colorScheme, Icons.person_rounded,
                        'Ata adı: ${teacher.fatherName}'),
                  if (teacher.gender != null)
                    _teacherInfoRow(
                        colorScheme, Icons.wc_rounded, 'Cins: ${teacher.gender}'),
                  if (teacher.birthDate != null)
                    _teacherInfoRow(
                        colorScheme,
                        Icons.cake_rounded,
                        'Doğum: ${dateFormat.format(teacher.birthDate!)}'),
                  if (teacher.finCode != null)
                    _teacherInfoRow(colorScheme, Icons.pin_rounded,
                        'FIN: ${teacher.finCode}'),
                  if (teacher.phone.isNotEmpty)
                    _teacherInfoRow(colorScheme, Icons.phone_rounded,
                        'Telefon: ${teacher.phone}'),
                  if (teacher.email != null)
                    _teacherInfoRow(
                        colorScheme, Icons.alternate_email_rounded, teacher.email!),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _teacherDetailBox(
    BuildContext ctx,
    AppPalette palette, {
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(ctx).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.borderHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 7),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ...children,
        ],
      ),
    );
  }

  Widget _teacherInfoRow(
    ColorScheme colorScheme,
    IconData icon,
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Sinfə müəllim təyin etmə dialoqu
  void _showAssignTeacherDialog(
    BuildContext context,
    AppState appState,
    String className,
  ) {
    final palette = AppPalette.of(context);
    String? teacherId;
    final subjectCtrl = TextEditingController();
    bool isCurator = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: Text(
                '$className — Müəllim Təyin Et',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: teacherId,
                    decoration: InputDecoration(
                      labelText: 'Müəllim *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    items: [
                      for (final t in appState.users
                          .where((u) => u.role == UserRole.teacher))
                        DropdownMenuItem(
                          value: t.id,
                          child: Text(
                            '${t.fullName} (${t.subject ?? "Müəllim"})${t.assignedClasses.contains(className) ? " ✓" : ""}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                    ],
                    onChanged: (v) {
                      setDialog(() => teacherId = v);
                      final matches = appState.users
                          .where((u) => u.id == v)
                          .toList();
                      final t = matches.isEmpty ? null : matches.first;
                      if (t != null && (t.subject ?? '').isNotEmpty) {
                        subjectCtrl.text = t.subject!;
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: subjectCtrl,
                    decoration: InputDecoration(
                      labelText: 'Bu sinifdə oxudulan fənn',
                      hintText: 'Məs: Riyaziyyat',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Sinif rəhbəri kimi təyin et',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    value: isCurator,
                    activeThumbColor: palette.brandGold,
                    onChanged: (v) => setDialog(() => isCurator = v),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Ləğv et'),
                ),
                FilledButton(
                  onPressed: () {
                    if (teacherId != null) {
                      appState.assignTeacherToClass(
                        teacherId: teacherId!,
                        className: className,
                        subject: subjectCtrl.text.trim().isEmpty
                            ? null
                            : subjectCtrl.text.trim(),
                        isClassTeacher: isCurator,
                      );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Müəllim sinifə təyin edildi!'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }
                  },
                  child: const Text('Təyin Et'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Yeni sinif yaratma sheeti — sadə,Diqqət yayındırmayan form
  void _showCreateClassSheet(
    BuildContext context,
    AppPalette palette,
    AppState appState,
  ) {
    final nameCtrl = TextEditingController();
    final roomCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    const yearOptions = ['2025 - 2026', '2026 - 2027', '2024 - 2025'];
    String academicYear = yearOptions.first;
    String? curatorId;
    final colorScheme = Theme.of(context).colorScheme;

    showAppSheet(
      context,
      maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheet) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yeni sinif əlavə et',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Adı tələbidir; digər məlumatlar sonradan əlavə edilə bilər.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Sinif adı *',
                      hintText: 'Məs: 10B, 11A, 8A',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: roomCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Sinif otağı',
                      hintText: 'Məs: 305',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Təhsil ili',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: [
                      for (final year in yearOptions)
                        GestureDetector(
                          onTap: () => setSheet(() => academicYear = year),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: academicYear == year
                                  ? palette.brandRoyal
                                  : palette.surface1,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: academicYear == year
                                    ? palette.brandRoyal
                                    : palette.borderHairline,
                              ),
                            ),
                            child: Text(
                              year,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: academicYear == year
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: academicYear == year
                                    ? Colors.white
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: curatorId,
                    decoration: InputDecoration(
                      labelText: 'Sinif rəhbəri (kurator)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Seçilməyib', style: TextStyle(fontSize: 13)),
                      ),
                      for (final t in appState.users
                          .where((u) => u.role == UserRole.teacher))
                        DropdownMenuItem(
                          value: t.id,
                          child: Text(
                            t.fullName,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                    ],
                    onChanged: (v) => setSheet(() => curatorId = v),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Qeyd',
                      hintText: 'Sinif haqqında əlavə məlumat...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.brandRoyal,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      onPressed: () {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;
                        Navigator.pop(ctx);
                        appState.addNewClass(
                          name,
                          room: roomCtrl.text.trim().isEmpty
                              ? null
                              : roomCtrl.text.trim(),
                          curatorTeacherId: curatorId,
                          academicYear: academicYear,
                          note: noteCtrl.text.trim().isEmpty
                              ? null
                              : noteCtrl.text.trim(),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('"$name" sinifi yaradıldı!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      },
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text(
                        'Sinifi yarat',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPromoteClassDialog(
    BuildContext context,
    AppState appState,
    String fromClass,
  ) {
    final match = RegExp(r'^(\d+)(.*)$').firstMatch(fromClass);
    String suggested;
    if (match != null) {
      final gradeNum = int.tryParse(match.group(1)!) ?? 9;
      final suffix = match.group(2) ?? '';
      if (gradeNum >= 11) {
        suggested = 'Məzun-$fromClass';
      } else {
        suggested = '${gradeNum + 1}$suffix';
      }
    } else {
      suggested = '$fromClass-Yüksəldilmiş';
    }

    final targetCtrl = TextEditingController(text: suggested);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Text(
            '🚀 $fromClass Sinifini Yüksəlt',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$fromClass sinfindəki bütün şagirdlərin sinfi bir kliklə növbəti tədris sinfinə keçiriləcək.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: targetCtrl,
                decoration: InputDecoration(
                  labelText: 'Yeni Sinif Adı *',
                  hintText: 'Məs: 10B',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Ləğv et'),
            ),
            FilledButton(
              onPressed: () {
                if (targetCtrl.text.trim().isNotEmpty) {
                  final toClass = targetCtrl.text.trim();
                  // Hədəf sinif artıq mövcuddursa üzərinə yazma —
                  // əks halda onun siyahısı və dərs cədvəli itir.
                  final exists = appState.allDistinctClasses.any(
                    (c) =>
                        c.toLowerCase() == toClass.toLowerCase() &&
                        c.toLowerCase() != fromClass.toLowerCase(),
                  );
                  if (exists) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '"$toClass" sinfi artıq mövcuddur — fərqli ad seçin.',
                        ),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                    return;
                  }
                  appState.promoteClass(fromClass, toClass);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '$fromClass sinfi uğurla $toClass sinfinə yüksəldildi!',
                      ),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Yüksəlt'),
            ),
          ],
        );
      },
    );
  }
}
