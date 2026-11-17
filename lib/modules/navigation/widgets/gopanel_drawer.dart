import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/utils/adaptive_route.dart';
import '../../../providers/app_state.dart';
import '../../shared/widgets/dashboard_kit.dart';

// Screens
import '../../academic_ops/screens/academic_notes_screen.dart';
import '../../academic_ops/screens/academic_statuses_screen.dart';
import '../../academic_ops/screens/academic_years_screen.dart';
import '../../academic_ops/screens/ambulatory_requests_screen.dart';
import '../../academic_ops/screens/assignments_management_screen.dart';
import '../../academic_ops/screens/club_journal_screen.dart';
import '../../academic_ops/screens/clubs_screen.dart';
import '../../academic_ops/screens/curriculums_screen.dart';
import '../../academic_ops/screens/excused_absences_screen.dart';
import '../../academic_ops/screens/final_grading_screen.dart';
import '../../academic_ops/screens/graduations_screen.dart';
import '../../academic_ops/screens/parallel_lessons_screen.dart';
import '../../academic_ops/screens/parents_management_screen.dart';
import '../../academic_ops/screens/rooms_screen.dart';
import '../../academic_ops/screens/subjects_screen.dart';
import '../../academic_ops/screens/teachers_management_screen.dart';
import '../../academic_ops/screens/time_slots_screen.dart';
import '../../academic_ops/screens/transition_exceptions_screen.dart';
import '../../admin/screens/admin_timetable_management_screen.dart';
import '../../admin/screens/admin_users_screen.dart';
import '../../admin/screens/class_management_screen.dart';
import '../../admin/screens/role_management_screen.dart';
import '../../admin/screens/student_management_screen.dart';
import '../../exams/screens/exam_categories_screen.dart';
import '../../exams/screens/exam_results_screen.dart';
import '../../exams/screens/exams_screen.dart';
import '../../exams/screens/student_applications_screen.dart';
import '../../finance/screens/finance_dictionary_screen.dart';
import '../../finance/screens/general_ledger_screen.dart';
import '../../finance/screens/payroll_screen.dart';
import '../../finance/screens/student_invoices_screen.dart';
import '../../finance/screens/student_payments_screen.dart';
import '../../hr/screens/contracts_screen.dart';
import '../../hr/screens/employee_attendance_screen.dart';
import '../../hr/screens/employee_documents_screen.dart';
import '../../hr/screens/employees_screen.dart';
import '../../journal/screens/api_journal_screen.dart';
import '../../library_ops/screens/book_loans_screen.dart';
import '../../library_ops/screens/book_reservations_screen.dart';
import '../../medical_ops/screens/medical_journal_screen.dart';
import '../../parent/screens/grades_analytics_screen.dart';
import '../../parent/screens/parent_tickets_screen.dart';
import '../../tickets/screens/support_tickets_screen.dart';
import '../../tickets/screens/ticket_categories_screen.dart';
import '../../psicology_ops/screens/psychology_evaluation_screen.dart';
import '../../shared/screens/notifications_screen.dart';
import '../../shared/screens/settings_screen.dart';
import '../../statistics/screens/quality_control_screen.dart';
import '../../statistics/screens/school_attendance_stats_screen.dart';
import '../../statistics/screens/workload_report_screen.dart';
import '../../structure_ops/screens/organizational_structure_screen.dart';
import '../../structure_ops/screens/positions_screen.dart';
import '../../structure_ops/screens/staffing_tables_screen.dart';
import '../../student/screens/cafeteria_menu_screen.dart';
import '../../student/screens/library_screen.dart';
import '../../student/screens/meet_idrak_screen.dart';
import '../../system_logs/screens/activity_logs_screen.dart';
import '../../teacher/screens/qr_inventory_ticket_screen.dart';
import '../../teacher/screens/quick_grading_screen.dart';
import '../../teacher/screens/review_submissions_screen.dart';
import '../../teacher/screens/teacher_id_card_screen.dart';
import '../../teacher/screens/teacher_students_screen.dart';
import '../../teacher/screens/teacher_timetable_view_screen.dart';
import '../../warehouse_ops/screens/canteen_supply_screen.dart';
import '../../warehouse_ops/screens/inventorizations_screen.dart';

typedef DrawerSubItem = ({
  String permissionId,
  String title,
  IconData? icon,
  VoidCallback onTap,
});

typedef DrawerItem = ({
  String permissionId,
  String title,
  IconData icon,
  Color color,
  VoidCallback? onTap,
  List<DrawerSubItem>? subItems,
});

typedef MenuGroup = ({
  String id,
  String title,
  IconData icon,
  Color color,
  List<DrawerItem> items,
});

class GoPanelDrawer extends StatefulWidget {
  const GoPanelDrawer({super.key});

  @override
  State<GoPanelDrawer> createState() => _GoPanelDrawerState();
}

class _GoPanelDrawerState extends State<GoPanelDrawer> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _expandedGroups = {};
  final Set<String> _expandedSubmenus = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.pop(context); // close drawer
    Navigator.push(context, appRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final appState = context.watch<AppState>();
    final session = context.watch<SessionController>();
    final user = appState.currentUser;
    final query = _searchQuery.trim().toLowerCase();
    final hasMultipleRoles = (session.profile?.roles.length ?? user?.roleNames.length ?? 0) > 1;
    final activeRoleLabel = session.profile?.activeRole ?? user?.assignedRoleId ?? user?.position ?? 'İstifadəçi';

    final menuGroups = <MenuGroup>[
      // Müəllim Paneli (rol müəllim olduqda)
      if (user?.role == UserRole.teacher)
        (
          id: 'teacher_hub',
          title: 'Müəllim Paneli',
          icon: Icons.psychology_rounded,
          color: const Color(0xFF0EA5E9),
          items: [
            (
              permissionId: 'teacher_timetable',
              title: 'Dərs Cədvəlim',
              icon: Icons.calendar_month_rounded,
              color: const Color(0xFF7C3AED),
              onTap: () => _navigateTo(context, const TeacherTimetableViewScreen()),
              subItems: null,
            ),
            (
              permissionId: 'teacher_students',
              title: 'Şagirdlərim',
              icon: Icons.groups_rounded,
              color: const Color(0xFF0EA5E9),
              onTap: () => _navigateTo(context, const TeacherStudentsScreen()),
              subItems: null,
            ),
            (
              permissionId: 'teacher_grading',
              title: 'E-Jurnal & Qiymətləndirmə',
              icon: Icons.rate_review_rounded,
              color: const Color(0xFF9333EA),
              onTap: () => _navigateTo(context, const QuickGradingScreen()),
              subItems: null,
            ),
            (
              permissionId: 'teacher_assignments',
              title: 'Ev Tapşırıqları',
              icon: Icons.assignment_turned_in_rounded,
              color: const Color(0xFF0D9488),
              onTap: () => _navigateTo(context, const ReviewSubmissionsScreen()),
              subItems: null,
            ),
            (
              permissionId: 'teacher_meet',
              title: 'Meet İdrak (Canlı Dərs)',
              icon: Icons.video_camera_front_rounded,
              color: const Color(0xFF10B981),
              onTap: () => _navigateTo(context, const MeetIdrakScreen()),
              subItems: null,
            ),
            (
              permissionId: 'teacher_id_card',
              title: 'Digital ID Kartım',
              icon: Icons.badge_rounded,
              color: const Color(0xFF2563EB),
              onTap: () => _navigateTo(context, const TeacherIdCardScreen()),
              subItems: null,
            ),
            (
              permissionId: 'teacher_inventory',
              title: 'Texniki Dəstək & Ticket',
              icon: Icons.qr_code_scanner_rounded,
              color: const Color(0xFFEF4444),
              onTap: () => _navigateTo(context, const QrInventoryTicketScreen()),
              subItems: null,
            ),
          ],
        ),

      // 0. Şagird və Valideyn (Vahid Şagird Əməliyyatları Mərkəzi)
      (
        id: 'student_360',
        title: 'Şagird və Valideyn',
        icon: Icons.person_search_rounded,
        color: const Color(0xFF0284C7),
        items: [
          (
            permissionId: 'gopanel.academic.students.view',
            title: 'Şagirdlər (360° İdarəetmə)',
            icon: Icons.school_rounded,
            color: const Color(0xFF0EA5E9),
            onTap: () => _navigateTo(context, const StudentManagementScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.academic.parents.view',
            title: 'Valideynlər',
            icon: Icons.people_alt_rounded,
            color: const Color(0xFF6366F1),
            onTap: () => _navigateTo(context, const ParentsManagementScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.finance.student_contracts.view',
            title: 'Müqavilə və maliyyə',
            icon: Icons.receipt_long_rounded,
            color: const Color(0xFF0D9488),
            onTap: null,
            subItems: [
              (
                permissionId: 'gopanel.finance.student_contracts.view',
                title: 'Şagird müqavilələri',
                icon: Icons.description_rounded,
                onTap: () => _navigateTo(context, const StudentInvoicesScreen()),
              ),
              (
                permissionId: 'gopanel.finance.payments.view',
                title: 'Ödənişlər',
                icon: Icons.payments_rounded,
                onTap: () => _navigateTo(context, const StudentPaymentsScreen()),
              ),
            ],
          ),
          (
            permissionId: 'gopanel.academic.transitions.exceptions.view',
            title: 'Bölmə dəyişiklikləri',
            icon: Icons.alt_route_rounded,
            color: const Color(0xFFF59E0B),
            onTap: () => _navigateTo(context, const TransitionExceptionsScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.academic.students.admissions',
            title: 'Şagird qəbulu',
            icon: Icons.how_to_reg_rounded,
            color: const Color(0xFF059669),
            onTap: () => _navigateTo(context, const StudentApplicationsScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.academic.graduations.view',
            title: 'Məzunlar',
            icon: Icons.workspace_premium_rounded,
            color: const Color(0xFF3B82F6),
            onTap: () => _navigateTo(context, const GraduationsScreen()),
            subItems: null,
          ),
        ],
      ),

      // 1. E-məktəb (Ümumi Tədris və Məktəb İdarəetməsi)
      (
        id: 'academic',
        title: 'E-məktəb',
        icon: Icons.school_rounded,
        color: const Color(0xFF0EA5E9),
        items: [
          (
            permissionId: 'gopanel.academic.classes.view',
            title: 'Siniflər',
            icon: Icons.meeting_room_rounded,
            color: const Color(0xFF0D9488),
            onTap: () => _navigateTo(context, const ClassManagementScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.academic.parallel_lessons.view',
            title: 'Paralel dərslər',
            icon: Icons.layers_rounded,
            color: const Color(0xFF10B981),
            onTap: () => _navigateTo(context, const ParallelLessonsScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.academic.teachers.view',
            title: 'Müəllimlər',
            icon: Icons.cast_for_education_rounded,
            color: const Color(0xFF8B5CF6),
            onTap: () => _navigateTo(context, const TeachersManagementScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.academic.schedules.view',
            title: 'Cədvəl',
            icon: Icons.calendar_today_rounded,
            color: const Color(0xFF7C3AED),
            onTap: () => _navigateTo(context, const AdminTimetableManagementScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.academic.ejournal.attendance.view',
            title: 'Jurnal',
            icon: Icons.fact_check_rounded,
            color: const Color(0xFF2563EB),
            onTap: () => _navigateTo(context, const ApiJournalScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.academic.homeroom.excuses.view',
            title: 'Üzürlü qayıb sorğuları',
            icon: Icons.event_busy_rounded,
            color: const Color(0xFFE11D48),
            onTap: () => _navigateTo(context, const ExcusedAbsencesScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.academic.ejournal.grading.final',
            title: 'Yekun qiymətləndirmə',
            icon: Icons.military_tech_rounded,
            color: const Color(0xFFD97706),
            onTap: () => _navigateTo(context, const FinalGradingScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.academic.ejournal.assignments.view',
            title: 'Tapşırıqlar',
            icon: Icons.assignment_rounded,
            color: const Color(0xFF4F46E5),
            onTap: () => _navigateTo(context, const AssignmentsManagementScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.academic.ejournal.curriculums.view',
            title: 'Kurikulum',
            icon: Icons.auto_stories_rounded,
            color: const Color(0xFF8B5CF6),
            onTap: () => _navigateTo(context, const CurriculumsScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.academic.foundations.years.view',
            title: 'Akademik illər',
            icon: Icons.date_range_rounded,
            color: const Color(0xFF4F46E5),
            onTap: () => _navigateTo(context, const AcademicYearsScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.academic.foundations.statuses.view',
            title: 'Statuslar',
            icon: Icons.toggle_on_rounded,
            color: const Color(0xFF14B8A6),
            onTap: () => _navigateTo(context, const AcademicStatusesScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.academic.foundations.subjects.view',
            title: 'Fənnlər',
            icon: Icons.book_rounded,
            color: const Color(0xFF3B82F6),
            onTap: () => _navigateTo(context, const SubjectsScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.academic.foundations.rooms.view',
            title: 'Otaqlar',
            icon: Icons.apartment_rounded,
            color: const Color(0xFF06B6D4),
            onTap: () => _navigateTo(context, const RoomsScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.academic.foundations.time_slots.view',
            title: 'Zəng cədvəli',
            icon: Icons.notifications_active_rounded,
            color: const Color(0xFFD97706),
            onTap: () => _navigateTo(context, const TimeSlotsScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.academic.notes.view',
            title: 'Akademik qeydlər',
            icon: Icons.sticky_note_2_rounded,
            color: const Color(0xFF64748B),
            onTap: () => _navigateTo(context, const AcademicNotesScreen()),
            subItems: null,
          ),
        ],
      ),

      // Mədəniyyət və İncəsənət (Dərnəklər və Dərnək jurnalı)
      (
        id: 'art_and_development',
        title: 'Mədəniyyət və İncəsənət',
        icon: Icons.palette_rounded,
        color: const Color(0xFF8B5CF6),
        items: [
          (
            permissionId: 'gopanel.academic.clubs.journal.view',
            title: 'Dərnək jurnalı',
            icon: Icons.menu_book_rounded,
            color: const Color(0xFF059669),
            onTap: () => _navigateTo(context, const ClubJournalScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.academic.clubs.view',
            title: 'Dərnəklər',
            icon: Icons.sports_basketball_rounded,
            color: const Color(0xFFF97316),
            onTap: () => _navigateTo(context, const ClubsScreen()),
            subItems: null,
          ),
        ],
      ),

      // 2. İnsan resursları
      (
        id: 'hr',
        title: 'İnsan resursları',
        icon: Icons.badge_rounded,
        color: const Color(0xFF2563EB),
        items: [
          (
            permissionId: 'gopanel.structure.structures.view',
            title: 'Təşkilati struktur',
            icon: Icons.account_tree_rounded,
            color: const Color(0xFF2563EB),
            onTap: null,
            subItems: [
              (
                permissionId: 'gopanel.structure.structures.view',
                title: 'Strukturlar',
                icon: Icons.adjust_rounded,
                onTap: () => _navigateTo(context, const OrganizationalStructureScreen()),
              ),
              (
                permissionId: 'gopanel.structure.positions.view',
                title: 'Vəzifələr',
                icon: Icons.badge_outlined,
                onTap: () => _navigateTo(context, const PositionsScreen()),
              ),
              (
                permissionId: 'gopanel.structure.staffing_tables.view',
                title: 'Ştat cədvəli',
                icon: Icons.table_chart_outlined,
                onTap: () => _navigateTo(context, const StaffingTablesScreen()),
              ),
            ],
          ),
          (
            permissionId: 'gopanel.hr.employees.view',
            title: 'Əməkdaşlar',
            icon: Icons.people_alt_rounded,
            color: const Color(0xFF2563EB),
            onTap: () => _navigateTo(context, const EmployeesScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.hr.contracts.view',
            title: 'Müqavilə və sənədlər',
            icon: Icons.history_edu_rounded,
            color: const Color(0xFF0284C7),
            onTap: null,
            subItems: [
              (
                permissionId: 'gopanel.hr.contracts.view',
                title: 'Müqavilələr',
                icon: Icons.adjust_rounded,
                onTap: () => _navigateTo(context, const ContractsScreen()),
              ),
              (
                permissionId: 'gopanel.hr.documents.view',
                title: 'İşçi sənədləri',
                icon: Icons.adjust_rounded,
                onTap: () => _navigateTo(context, const EmployeeDocumentsScreen()),
              ),
            ],
          ),
          (
            permissionId: 'gopanel.documents.types.view',
            title: 'Sənəd idarəetməsi',
            icon: Icons.folder_shared_rounded,
            color: const Color(0xFF6366F1),
            onTap: null,
            subItems: [
              (
                permissionId: 'gopanel.documents.types.view',
                title: 'Sənəd tipləri',
                icon: Icons.adjust_rounded,
                onTap: () => _navigateTo(context, const EmployeeDocumentsScreen()),
              ),
              (
                permissionId: 'gopanel.documents.templates.view',
                title: 'Sənəd şablonları',
                icon: Icons.adjust_rounded,
                onTap: () => _navigateTo(context, const EmployeeDocumentsScreen()),
              ),
            ],
          ),
          (
            permissionId: 'gopanel.hr.attendances.view',
            title: 'Davamiyyət və təqvim',
            icon: Icons.calendar_month_rounded,
            color: const Color(0xFF0EA5E9),
            onTap: null,
            subItems: [
              (
                permissionId: 'gopanel.hr.attendances.view',
                title: 'Davamiyyət',
                icon: Icons.adjust_rounded,
                onTap: () => _navigateTo(context, const EmployeeAttendanceScreen()),
              ),
              (
                permissionId: 'gopanel.hr.teqvims.view',
                title: 'Təqvim',
                icon: Icons.adjust_rounded,
                onTap: () => _navigateTo(context, const EmployeeAttendanceScreen()),
              ),
            ],
          ),
          (
            permissionId: 'gopanel.field_groups.index',
            title: 'Dinamik bölmələr',
            icon: Icons.view_quilt_rounded,
            color: const Color(0xFF8B5CF6),
            onTap: null,
            subItems: [
              (
                permissionId: 'gopanel.field_groups.index',
                title: 'Sahə Qrupları',
                icon: Icons.adjust_rounded,
                onTap: () => _navigateTo(context, const OrganizationalStructureScreen()),
              ),
              (
                permissionId: 'gopanel.fields.index',
                title: 'Sahələr',
                icon: Icons.adjust_rounded,
                onTap: () => _navigateTo(context, const OrganizationalStructureScreen()),
              ),
            ],
          ),
        ],
      ),

      // 3. Maliyyə və mühasibatlıq
      (
        id: 'finance',
        title: 'Maliyyə və mühasibatlıq',
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFF16A34A),
        items: [
          (
            permissionId: 'gopanel.finance.payroll.view',
            title: 'Əmək haqqı',
            icon: Icons.payments_rounded,
            color: const Color(0xFF16A34A),
            onTap: null,
            subItems: [
              (
                permissionId: 'gopanel.finance.payroll.view',
                title: 'Əmək haqqı hesablanması',
                icon: Icons.adjust_rounded,
                onTap: () => _navigateTo(context, const PayrollScreen()),
              ),
              (
                permissionId: 'gopanel.finance.payroll.salary_list.view',
                title: 'Maaş cədvəli',
                icon: Icons.adjust_rounded,
                onTap: () => _navigateTo(context, const PayrollScreen()),
              ),
              (
                permissionId: 'gopanel.finance.payroll.archive.view',
                title: 'Maaş arxivi',
                icon: Icons.adjust_rounded,
                onTap: () => _navigateTo(context, const PayrollScreen()),
              ),
              (
                permissionId: 'gopanel.finance.tax_rules.view',
                title: 'Vergi şərtləri',
                icon: Icons.adjust_rounded,
                onTap: () => _navigateTo(context, const PayrollScreen()),
              ),
            ],
          ),
          (
            permissionId: 'gopanel.finance.ledger.view',
            title: 'Ümumi mühasibatlıq',
            icon: Icons.account_balance_rounded,
            color: const Color(0xFF059669),
            onTap: null,
            subItems: [
              (
                permissionId: 'gopanel.finance.ledger.view',
                title: 'Gəlir/xərc',
                icon: Icons.adjust_rounded,
                onTap: () => _navigateTo(context, const GeneralLedgerScreen()),
              ),
              (
                permissionId: 'gopanel.finance.reports.view',
                title: 'Maliyyə analizi',
                icon: Icons.adjust_rounded,
                onTap: () => _navigateTo(context, const GeneralLedgerScreen()),
              ),
            ],
          ),
          (
            permissionId: 'gopanel.finance.dictionary.view',
            title: 'Maliyyə tənzimləmələri',
            icon: Icons.menu_book_rounded,
            color: const Color(0xFF0284C7),
            onTap: null,
            subItems: [
              (
                permissionId: 'gopanel.finance.dictionary.bank_accounts.view',
                title: 'Bank hesabları',
                icon: Icons.adjust_rounded,
                onTap: () => _navigateTo(context, const FinanceDictionaryScreen()),
              ),
              (
                permissionId: 'gopanel.finance.dictionary.external_entities.view',
                title: 'Xarici qurumlar',
                icon: Icons.adjust_rounded,
                onTap: () => _navigateTo(context, const FinanceDictionaryScreen()),
              ),
              (
                permissionId: 'gopanel.finance.dictionary.note_templates.view',
                title: 'Qeyd şablonları',
                icon: Icons.adjust_rounded,
                onTap: () => _navigateTo(context, const FinanceDictionaryScreen()),
              ),
              (
                permissionId: 'gopanel.finance.dictionary.transport_rates.view',
                title: 'Nəqliyyat tarifləri',
                icon: Icons.adjust_rounded,
                onTap: () => _navigateTo(context, const FinanceDictionaryScreen()),
              ),
              (
                permissionId: 'gopanel.finance.tuition_fees.view',
                title: 'Təhsil haqları',
                icon: Icons.adjust_rounded,
                onTap: () => _navigateTo(context, const FinanceDictionaryScreen()),
              ),
              (
                permissionId: 'gopanel.finance.dictionary.categories.view',
                title: 'Maliyyə kateqoriyaları',
                icon: Icons.adjust_rounded,
                onTap: () => _navigateTo(context, const FinanceDictionaryScreen()),
              ),
            ],
          ),
        ],
      ),

      // 4. Təsərrüfat və anbar
      (
        id: 'warehouse',
        title: 'Anbar və inventarlaşma',
        icon: Icons.warehouse_rounded,
        color: const Color(0xFFEA580C),
        items: [
          (
            permissionId: 'gopanel.warehouse.items.view',
            title: 'Anbar qalığı',
            icon: Icons.inventory_2_rounded,
            color: const Color(0xFFEA580C),
            onTap: () => _navigateTo(context, const InventorizationsScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.warehouse.logs.view',
            title: 'Əməliyyat tarixçəsi',
            icon: Icons.history_rounded,
            color: const Color(0xFFD97706),
            onTap: () => _navigateTo(context, const InventorizationsScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.warehouse_actions.inventorizations.view',
            title: 'İnventarizasiya',
            icon: Icons.fact_check_rounded,
            color: const Color(0xFFB45309),
            onTap: () => _navigateTo(context, const InventorizationsScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.canteen.canteens.view',
            title: 'Yeməkxana təyinatları',
            icon: Icons.lunch_dining_rounded,
            color: const Color(0xFFF97316),
            onTap: () => _navigateTo(context, const CanteenSupplyScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.canteen.menu.view',
            title: 'Həftəlik Menyu',
            icon: Icons.restaurant_menu_rounded,
            color: const Color(0xFFEAB308),
            onTap: () => _navigateTo(context, const CafeteriaMenuScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.canteen.templates.view',
            title: 'Şablon Menyular',
            icon: Icons.table_restaurant_rounded,
            color: const Color(0xFFCA8A04),
            onTap: () => _navigateTo(context, const CanteenSupplyScreen()),
            subItems: null,
          ),
        ],
      ),

      // 5. Tibbi xidmət
      (
        id: 'medical',
        title: 'Tibbi xidmət',
        icon: Icons.health_and_safety_rounded,
        color: const Color(0xFFEF4444),
        items: [
          (
            permissionId: 'gopanel.admissions.ambulatory_requests.view',
            title: 'Ambulator sorğuları',
            icon: Icons.local_hospital_rounded,
            color: const Color(0xFFEF4444),
            onTap: () => _navigateTo(context, const AmbulatoryRequestsScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.medical.medical_results.view',
            title: 'Tibbi müayinə nəticələri',
            icon: Icons.medical_services_rounded,
            color: const Color(0xFFEF4444),
            onTap: () => _navigateTo(context, const MedicalJournalScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.medical.excuses.view',
            title: 'Üzürlü qayıb sorğuları',
            icon: Icons.event_busy_rounded,
            color: const Color(0xFFF43F5E),
            onTap: () => _navigateTo(context, const ExcusedAbsencesScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.medical.allergy_sickness.view',
            title: 'Xəstəlik kateqoriyası',
            icon: Icons.category_rounded,
            color: const Color(0xFFE11D48),
            onTap: () => _navigateTo(context, const MedicalJournalScreen()),
            subItems: null,
          ),
        ],
      ),

      // 6. Psixologiya əməliyyatları
      (
        id: 'psychology',
        title: 'Psixologiya əməliyyatları',
        icon: Icons.psychology_rounded,
        color: const Color(0xFF8B5CF6),
        items: [
          (
            permissionId: 'gopanel.psicology.psicology_results.view',
            title: 'Psixologiya nəticələri',
            icon: Icons.psychology_rounded,
            color: const Color(0xFF8B5CF6),
            onTap: () => _navigateTo(context, const PsychologyEvaluationScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.psicology.psicology_creterions.view',
            title: 'Psixologiya kriteriyaları',
            icon: Icons.rule_rounded,
            color: const Color(0xFF7C3AED),
            onTap: () => _navigateTo(context, const PsychologyEvaluationScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.psicology.student_first_time_applications.view',
            title: 'Yeni tələbələrin dəyərləndirilməsi',
            icon: Icons.person_add_rounded,
            color: const Color(0xFF6366F1),
            onTap: () => _navigateTo(context, const StudentApplicationsScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.psicology.transition_exceptions.view',
            title: 'Bölmə dəyişiklikləri',
            icon: Icons.alt_route_rounded,
            color: const Color(0xFFA855F7),
            onTap: () => _navigateTo(context, const TransitionExceptionsScreen()),
            subItems: null,
          ),
        ],
      ),

      // 7. İmtahan
      (
        id: 'exams',
        title: 'İmtahan',
        icon: Icons.quiz_rounded,
        color: const Color(0xFFDC2626),
        items: [
          (
            permissionId: 'gopanel.exams.exam_categories.view',
            title: 'İmtahan kateqoriyaları',
            icon: Icons.pie_chart_rounded,
            color: const Color(0xFF0284C7),
            onTap: () => _navigateTo(context, const ExamCategoriesScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.exams.exams.view',
            title: 'İmtahanlar',
            icon: Icons.assignment_turned_in_rounded,
            color: const Color(0xFFDC2626),
            onTap: () => _navigateTo(context, const ExamsScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.exams.results.view',
            title: 'İmtahan nəticələri',
            icon: Icons.leaderboard_rounded,
            color: const Color(0xFFF59E0B),
            onTap: () => _navigateTo(context, const ExamResultsScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.exams.student_first_time_applications.view',
            title: 'Yeni tələbələrin dəyərləndirilməsi',
            icon: Icons.person_search_rounded,
            color: const Color(0xFF2563EB),
            onTap: () => _navigateTo(context, const StudentApplicationsScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.exams.transition_exceptions.view',
            title: 'Bölmə dəyişiklikləri',
            icon: Icons.alt_route_rounded,
            color: const Color(0xFFD97706),
            onTap: () => _navigateTo(context, const TransitionExceptionsScreen()),
            subItems: null,
          ),
        ],
      ),

      // 8. Dəstək biletləri
      (
        id: 'tickets_group',
        title: 'Dəstək biletləri',
        icon: Icons.support_agent_rounded,
        color: const Color(0xFF9333EA),
        items: [
          (
            permissionId: 'gopanel.tickets.view',
            title: 'Dəstək biletləri',
            icon: Icons.support_agent_rounded,
            color: const Color(0xFF9333EA),
            onTap: () => _navigateTo(context, const SupportTicketsScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.tickets.categories.view',
            title: 'Bilet kateqoriyaları',
            icon: Icons.category_rounded,
            color: const Color(0xFFA855F7),
            onTap: () => _navigateTo(context, const TicketCategoriesScreen()),
            subItems: null,
          ),
        ],
      ),

      // 9. Kitabxana
      (
        id: 'library',
        title: 'Kitabxana',
        icon: Icons.local_library_rounded,
        color: const Color(0xFF7C3AED),
        items: [
          (
            permissionId: 'gopanel.library.categories.view',
            title: 'Kateqoriyalar',
            icon: Icons.category_rounded,
            color: const Color(0xFF6D28D9),
            onTap: () => _navigateTo(context, const LibraryScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.library.books.view',
            title: 'Kitablar',
            icon: Icons.local_library_rounded,
            color: const Color(0xFF7C3AED),
            onTap: () => _navigateTo(context, const LibraryScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.library.loans.view',
            title: 'Kitab icarələri',
            icon: Icons.auto_stories_rounded,
            color: const Color(0xFF9333EA),
            onTap: () => _navigateTo(context, const BookLoansScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.library.reservations.view',
            title: 'Kitab reservasiyaları',
            icon: Icons.bookmarks_rounded,
            color: const Color(0xFFD946EF),
            onTap: () => _navigateTo(context, const BookReservationsScreen()),
            subItems: null,
          ),
        ],
      ),

      // 10. Statistika və hesabatlar
      (
        id: 'stats',
        title: 'Statistika və hesabatlar',
        icon: Icons.analytics_rounded,
        color: const Color(0xFF0284C7),
        items: [
          (
            permissionId: 'gopanel.statistics.quality_control.view',
            title: 'Keyfiyyətə nəzarət',
            icon: Icons.fact_check_rounded,
            color: const Color(0xFF059669),
            onTap: () => _navigateTo(context, const QualityControlScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.statistics.attendance.view',
            title: 'Davamiyyət statistikası',
            icon: Icons.co_present_rounded,
            color: const Color(0xFF1D4ED8),
            onTap: () => _navigateTo(context, const SchoolAttendanceStatsScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.academic.statistics.performance',
            title: 'Şagird performans statistikası',
            icon: Icons.query_stats_rounded,
            color: const Color(0xFF0EA5E9),
            onTap: () => _navigateTo(context, const GradesAnalyticsScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.academic.statistics.assignments',
            title: 'Tapşırıq statistikası',
            icon: Icons.assignment_turned_in_rounded,
            color: const Color(0xFF6366F1),
            onTap: () => _navigateTo(context, const AssignmentsManagementScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.statistics.admissions.view',
            title: 'Qəbul statistikası',
            icon: Icons.how_to_reg_rounded,
            color: const Color(0xFF10B981),
            onTap: () => _navigateTo(context, const StudentApplicationsScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.statistics.leavers.view',
            title: 'Xaric edilənlərin statistikası',
            icon: Icons.person_remove_rounded,
            color: const Color(0xFFEF4444),
            onTap: () => _navigateTo(context, const GraduationsScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.statistics.monthly.view',
            title: 'Aylıq statistika',
            icon: Icons.calendar_view_month_rounded,
            color: const Color(0xFF3B82F6),
            onTap: () => _navigateTo(context, const SchoolAttendanceStatsScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.statistics.vacation.view',
            title: 'Məzuniyyət hesabatı',
            icon: Icons.beach_access_rounded,
            color: const Color(0xFFF59E0B),
            onTap: () => _navigateTo(context, const WorkloadReportScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.statistics.payment.view',
            title: 'Əmək haqqı hesabatı',
            icon: Icons.payments_rounded,
            color: const Color(0xFF16A34A),
            onTap: () => _navigateTo(context, const PayrollScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.statistics.warehouse.view',
            title: 'Anbar statistikası',
            icon: Icons.inventory_rounded,
            color: const Color(0xFFEA580C),
            onTap: () => _navigateTo(context, const InventorizationsScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.academic.teachers.report.view',
            title: 'İş yükü hesabatı',
            icon: Icons.table_view_rounded,
            color: const Color(0xFF0284C7),
            onTap: () => _navigateTo(context, const WorkloadReportScreen()),
            subItems: null,
          ),
        ],
      ),

      // 11. Məktəb tənzimləmələri
      (
        id: 'school_settings',
        title: 'Məktəb tənzimləmələri',
        icon: Icons.tune_rounded,
        color: const Color(0xFF0284C7),
        items: [
          (
            permissionId: 'gopanel.structure.companies.view',
            title: 'Məktəb və filiallar',
            icon: Icons.domain_rounded,
            color: const Color(0xFF0284C7),
            onTap: null,
            subItems: [
              (
                permissionId: 'gopanel.structure.companies.view',
                title: 'Məktəb',
                icon: Icons.adjust_rounded,
                onTap: () => _navigateTo(context, const OrganizationalStructureScreen()),
              ),
              (
                permissionId: 'gopanel.structure.filials.view',
                title: 'Filiallar',
                icon: Icons.adjust_rounded,
                onTap: () => _navigateTo(context, const OrganizationalStructureScreen()),
              ),
              (
                permissionId: 'gopanel.structure.warehouses.view',
                title: 'Anbarlar',
                icon: Icons.adjust_rounded,
                onTap: () => _navigateTo(context, const InventorizationsScreen()),
              ),
            ],
          ),
          (
            permissionId: 'gopanel.tools.code_generators.view',
            title: 'Sistem alətləri',
            icon: Icons.handyman_rounded,
            color: const Color(0xFF64748B),
            onTap: null,
            subItems: [
              (
                permissionId: 'gopanel.tools.code_generators.view',
                title: 'Kod yaradılması',
                icon: Icons.adjust_rounded,
                onTap: () => _navigateTo(context, const SettingsScreen()),
              ),
            ],
          ),
        ],
      ),

      // 12. Sistem və loqlar
      (
        id: 'system_and_logs',
        title: 'Sistem və loqlar',
        icon: Icons.settings_suggest_rounded,
        color: const Color(0xFF475569),
        items: [
          (
            permissionId: 'gopanel.settings.site.view',
            title: 'Sistem parametrləri',
            icon: Icons.settings_applications_rounded,
            color: const Color(0xFF475569),
            onTap: () => _navigateTo(context, const SettingsScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.dashboard_banners.view',
            title: 'Ana Səhifə Bannerləri',
            icon: Icons.view_carousel_rounded,
            color: const Color(0xFF0284C7),
            onTap: () => _navigateTo(context, const SettingsScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.notifications.view',
            title: 'Bildirişlər',
            icon: Icons.campaign_rounded,
            color: const Color(0xFFE11D48),
            onTap: () => _navigateTo(context, const NotificationsScreen()),
            subItems: null,
          ),
          (
            permissionId: 'gopanel.languages.view',
            title: 'Lokalizasiya',
            icon: Icons.translate_rounded,
            color: const Color(0xFF059669),
            onTap: null,
            subItems: [
              (
                permissionId: 'gopanel.languages.view',
                title: 'Dillər',
                icon: Icons.adjust_rounded,
                onTap: () => _navigateTo(context, const SettingsScreen()),
              ),
              (
                permissionId: 'gopanel.translations.view',
                title: 'Tərcümələr',
                icon: Icons.adjust_rounded,
                onTap: () => _navigateTo(context, const SettingsScreen()),
              ),
            ],
          ),
          (
            permissionId: 'gopanel.admins.view',
            title: 'Admin və vəzifələr',
            icon: Icons.admin_panel_settings_rounded,
            color: const Color(0xFF0F766E),
            onTap: null,
            subItems: [
              (
                permissionId: 'gopanel.admins.view',
                title: 'Adminlər',
                icon: Icons.adjust_rounded,
                onTap: () => _navigateTo(context, const AdminUsersScreen()),
              ),
              (
                permissionId: 'gopanel.roles.view',
                title: 'Vəzifələr',
                icon: Icons.adjust_rounded,
                onTap: () => _navigateTo(context, const RoleManagementScreen()),
              ),
              (
                permissionId: 'gopanel.permissions.view',
                title: 'İcazələr',
                icon: Icons.adjust_rounded,
                onTap: () => _navigateTo(context, const RoleManagementScreen()),
              ),
            ],
          ),
          (
            permissionId: 'gopanel.activity.history.view',
            title: 'Loqlar və tarixçə',
            icon: Icons.history_toggle_off_rounded,
            color: const Color(0xFF64748B),
            onTap: null,
            subItems: [
              (
                permissionId: 'gopanel.activity.history.view',
                title: 'Hərəkət Tarixçəsi',
                icon: Icons.adjust_rounded,
                onTap: () => _navigateTo(context, const ActivityLogsScreen()),
              ),
              (
                permissionId: 'gopanel.activity.logs.view',
                title: 'Sistem loqları',
                icon: Icons.adjust_rounded,
                onTap: () => _navigateTo(context, const ActivityLogsScreen()),
              ),
            ],
          ),
        ],
      ),
    ];

    return Drawer(
      backgroundColor: palette.bgBase,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0A1428),
                    Color(0xFF101D36),
                    Color(0xFF172554),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.12),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.school_rounded,
                            color: AppColors.goldLight,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'İDRAK LİSEYİ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              user?.fullName ?? 'GoPanel İdarəetmə',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.80),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.settings_outlined, color: Colors.white70, size: 20),
                        onPressed: () => _navigateTo(context, const SettingsScreen()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: hasMultipleRoles
                        ? () {
                            Navigator.pop(context);
                            showEmployeeRoleSwitcherSheet(context);
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_user_rounded, color: AppColors.goldLight, size: 15),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Aktiv rol: $activeRoleLabel',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.goldLight,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (hasMultipleRoles) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.gold.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.swap_horiz_rounded, color: Colors.white, size: 12),
                                  SizedBox(width: 3),
                                  Text(
                                    'Dəyiş',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (session.canSwitchGuard) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () async {
                        Navigator.pop(context);
                        final ok = await context.read<AppState>().switchGuard(context);
                        if (!ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Rejim dəyişdirilə bilmədi')),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.6)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.swap_horiz_rounded, color: Color(0xFF34D399), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ' rejiminə keçid',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (session.linkedGuardName != null)
                                    Text(
                                      session.linkedGuardName!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.8),
                                        fontSize: 10.5,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 11),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: TextStyle(fontSize: 13, color: palette.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Modul axtar (məs: Davamiyyət, Təqvim)...',
                  hintStyle: TextStyle(fontSize: 12, color: palette.textMuted),
                  prefixIcon: Icon(Icons.search_rounded, size: 18, color: palette.textMuted),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: palette.surface1,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: palette.borderHairline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: palette.borderHairline),
                  ),
                ),
              ),
            ),

            // Accordion Groups List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 20),
                children: [
                  for (final group in menuGroups) ...[
                    Builder(
                      builder: (ctx) {
                        // Filter visible items matching real Spatie permissions
                        final visibleItems = <({
                          DrawerItem item,
                          List<DrawerSubItem>? filteredSubs,
                        })>[];

                        for (final item in group.items) {
                          if (item.subItems != null && item.subItems!.isNotEmpty) {
                            // Submenu item: visible if ANY sub-item is permitted
                            final matchingSubs = item.subItems!.where((sub) {
                              if (sub.permissionId.isNotEmpty && !appState.hasPermission(sub.permissionId)) {
                                return false;
                              }
                              if (query.isEmpty) return true;
                              return sub.title.toLowerCase().contains(query) ||
                                  item.title.toLowerCase().contains(query) ||
                                  group.title.toLowerCase().contains(query);
                            }).toList();

                            if (matchingSubs.isNotEmpty) {
                              visibleItems.add((item: item, filteredSubs: matchingSubs));
                            }
                          } else {
                            // Flat item
                            if (item.permissionId.isNotEmpty && !appState.hasPermission(item.permissionId)) {
                              continue;
                            }
                            if (query.isEmpty ||
                                item.title.toLowerCase().contains(query) ||
                                group.title.toLowerCase().contains(query)) {
                              visibleItems.add((item: item, filteredSubs: null));
                            }
                          }
                        }

                        // Exactly like Web GoPanel: if a group has 0 visible items, do not render the group
                        if (visibleItems.isEmpty) return const SizedBox.shrink();

                        final isGroupExpanded = query.isNotEmpty || _expandedGroups.contains(group.id);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: palette.surface1,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: palette.borderHairline),
                          ),
                          child: Column(
                            children: [
                              // Group Header (E-məktəb, Maliyyə, etc.)
                              InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () {
                                  setState(() {
                                    if (_expandedGroups.contains(group.id)) {
                                      _expandedGroups.remove(group.id);
                                    } else {
                                      _expandedGroups.add(group.id);
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                  decoration: isGroupExpanded
                                      ? BoxDecoration(
                                          color: group.color.withValues(alpha: 0.10),
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                        )
                                      : null,
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(7),
                                        decoration: BoxDecoration(
                                          color: group.color.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(9),
                                        ),
                                        child: Icon(group.icon, size: 17, color: group.color),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          group.title,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: palette.textPrimary,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: group.color.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${visibleItems.length}',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                            color: group.color,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      AnimatedRotation(
                                        turns: isGroupExpanded ? 0.5 : 0.0,
                                        duration: const Duration(milliseconds: 220),
                                        curve: Curves.easeOutCubic,
                                        child: Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 18,
                                          color: palette.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Items inside group
                              ClipRect(
                                child: AnimatedSize(
                                  duration: const Duration(milliseconds: 240),
                                  curve: Curves.easeOutCubic,
                                  alignment: Alignment.topCenter,
                                  child: isGroupExpanded
                                      ? Padding(
                                  padding: const EdgeInsets.fromLTRB(6, 4, 6, 8),
                                  child: Column(
                                    children: [
                                      for (final entry in visibleItems) ...[
                                        if (entry.filteredSubs != null) ...[
                                          // 2nd level expandable item (e.g. Davamiyyət və təqvim)
                                          Builder(
                                            builder: (subCtx) {
                                              final subKey = '${group.id}_${entry.item.title}';
                                              final isSubExpanded = query.isNotEmpty || _expandedSubmenus.contains(subKey);
                                              final isDark = Theme.of(context).brightness == Brightness.dark;
                                              final subActiveColor = isDark ? const Color(0xFF38BDF8) : palette.brandAzure;
                                              final subBgColor = isDark
                                                  ? const Color(0xFF131D31)
                                                  : const Color(0xFFF0F4F9);

                                              return AnimatedContainer(
                                                duration: const Duration(milliseconds: 200),
                                                curve: Curves.easeInOut,
                                                margin: const EdgeInsets.only(bottom: 4),
                                                decoration: BoxDecoration(
                                                  color: isSubExpanded ? subBgColor : Colors.transparent,
                                                  borderRadius: BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: isSubExpanded
                                                        ? subActiveColor.withValues(alpha: 0.25)
                                                        : Colors.transparent,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Column(
                                                  children: [
                                                    InkWell(
                                                      borderRadius: BorderRadius.circular(10),
                                                      onTap: () {
                                                        setState(() {
                                                          if (_expandedSubmenus.contains(subKey)) {
                                                            _expandedSubmenus.remove(subKey);
                                                          } else {
                                                            _expandedSubmenus.add(subKey);
                                                          }
                                                        });
                                                      },
                                                      child: Padding(
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              entry.item.icon,
                                                              size: 16,
                                                              color: isSubExpanded
                                                                  ? subActiveColor
                                                                  : entry.item.color,
                                                            ),
                                                            const SizedBox(width: 10),
                                                            Expanded(
                                                              child: Text(
                                                                entry.item.title,
                                                                style: TextStyle(
                                                                  fontSize: 12.5,
                                                                  fontWeight: isSubExpanded ? FontWeight.w800 : FontWeight.w600,
                                                                  color: isSubExpanded
                                                                      ? subActiveColor
                                                                      : palette.textPrimary,
                                                                ),
                                                              ),
                                                            ),
                                                            AnimatedRotation(
                                                              turns: isSubExpanded ? 0.5 : 0.0,
                                                              duration: const Duration(milliseconds: 200),
                                                              curve: Curves.easeOutCubic,
                                                              child: Icon(
                                                                Icons.keyboard_arrow_down_rounded,
                                                                size: 16,
                                                                color: isSubExpanded
                                                                    ? subActiveColor
                                                                    : palette.textMuted,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    ClipRect(
                                                      child: AnimatedSize(
                                                        duration: const Duration(milliseconds: 200),
                                                        curve: Curves.easeOutCubic,
                                                        alignment: Alignment.topCenter,
                                                        child: isSubExpanded
                                                            ? Padding(
                                                                padding: const EdgeInsets.only(bottom: 6),
                                                                child: Column(
                                                                  children: [
                                                                    for (final subItem in entry.filteredSubs!)
                                                                      InkWell(
                                                                        borderRadius: BorderRadius.circular(8),
                                                                        onTap: subItem.onTap,
                                                                        child: Padding(
                                                                          padding: const EdgeInsets.fromLTRB(28, 6, 12, 6),
                                                                          child: Row(
                                                                            children: [
                                                                              Icon(
                                                                                subItem.icon ?? Icons.adjust_rounded,
                                                                                size: 14,
                                                                                color: subActiveColor.withValues(alpha: 0.8),
                                                                              ),
                                                                              const SizedBox(width: 10),
                                                                              Expanded(
                                                                                child: Text(
                                                                                  subItem.title,
                                                                                  style: TextStyle(
                                                                                    fontSize: 12,
                                                                                    fontWeight: FontWeight.w600,
                                                                                    color: palette.textPrimary,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                              Icon(
                                                                                Icons.chevron_right_rounded,
                                                                                size: 15,
                                                                                color: palette.textMuted.withValues(alpha: 0.5),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      ),
                                                                  ],
                                                                ),
                                                              )
                                                            : const SizedBox.shrink(),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ] else ...[
                                          // Flat item (direct tap)
                                          InkWell(
                                            borderRadius: BorderRadius.circular(10),
                                            onTap: entry.item.onTap,
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
                                              child: Row(
                                                children: [
                                                  Icon(entry.item.icon, size: 16, color: entry.item.color),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: Text(
                                                      entry.item.title,
                                                      style: TextStyle(
                                                        fontSize: 12.5,
                                                        fontWeight: FontWeight.w600,
                                                        color: palette.textPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                  Icon(
                                                    Icons.chevron_right_rounded,
                                                    size: 16,
                                                    color: palette.textMuted.withValues(alpha: 0.5),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ),
                  );
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
