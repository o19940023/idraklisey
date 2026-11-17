import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/services/school_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/employee_model.dart';
import '../../../providers/app_state.dart';
import 'contracts_screen.dart';
import 'employee_documents_screen.dart';
import 'employee_profile_screen.dart';
import 'employee_store_screen.dart';
import 'salary_calculator_screen.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Employee> _employees = [];
  bool _isLoading = false;

  // Filters
  String _selectedCategory = 'ALL'; // ALL, TEACHERS, ADMIN, INACTIVE
  String _selectedDepartment = 'Hamısı';
  String _selectedFilial = 'Hamısı';
  String _selectedSector = 'Hamısı';
  bool _hideSalaries = false;
  bool _showAdvancedFilters = false;

  final List<String> _filials = ['Hamısı', 'Bakı filialı', 'Sumqayıt filialı'];
  final List<String> _sectors = ['Hamısı', 'Azərbaycan', 'Rus', 'İngilis'];

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    try {
      final rawData = await SchoolApiService.instance.fetchEmployees();
      if (rawData.isNotEmpty) {
        final parsed = rawData.map((m) => Employee.fromJson(m)).toList();
        if (mounted) {
          setState(() {
            _employees = parsed;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Error loading employees from mobile api: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  List<String> get _dynamicDepartments {
    final set = <String>{'Hamısı'};
    for (final e in _employees) {
      if (e.department.trim().isNotEmpty) {
        set.add(e.department.trim());
      }
    }
    return set.toList();
  }

  List<Employee> get _filteredEmployees {
    final query = _searchController.text.trim().toLowerCase();

    return _employees.where((emp) {
      // Category filter
      if (_selectedCategory == 'TEACHERS' && (!emp.isTeacher || !emp.isActive)) return false;
      if (_selectedCategory == 'ADMIN' && (emp.isTeacher || !emp.isActive)) return false;
      if (_selectedCategory == 'INACTIVE' && emp.isActive) return false;

      // Department filter
      if (_selectedDepartment != 'Hamısı' && emp.department != _selectedDepartment) {
        return false;
      }

      // Filial filter
      if (_selectedFilial != 'Hamısı' && (emp.filial ?? '') != _selectedFilial) {
        return false;
      }

      // Sector filter
      if (_selectedSector != 'Hamısı' && (emp.sector ?? '') != _selectedSector) {
        return false;
      }

      // Query filter
      if (query.isNotEmpty) {
        final match = emp.fullName.toLowerCase().contains(query) ||
            emp.firstName.toLowerCase().contains(query) ||
            emp.lastName.toLowerCase().contains(query) ||
            emp.fatherName.toLowerCase().contains(query) ||
            emp.code.toLowerCase().contains(query) ||
            emp.finCode.toLowerCase().contains(query) ||
            emp.position.toLowerCase().contains(query) ||
            emp.department.toLowerCase().contains(query) ||
            emp.subject.toLowerCase().contains(query) ||
            emp.phone.toLowerCase().contains(query) ||
            emp.email.toLowerCase().contains(query);
        if (!match) return false;
      }

      return true;
    }).toList();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final clean = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) return;
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final clean = email.trim();
    if (clean.isEmpty) return;
    final uri = Uri.parse('mailto:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _confirmDeleteEmployee(Employee emp) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
            const SizedBox(width: 8),
            const Text('Əməkdaşı Sil'),
          ],
        ),
        content: Text(
          '${emp.fullName} (${emp.code}) adlı əməkdaşın qeydiyyatını sistemdən silmək istədiyinizə əminsiniz?\n\nBu əməliyyat əməkdaşın aktiv müqaviləsini və əlaqəli məlumatlarını ləğv edəcək.',
          style: const TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('İmtina'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final success = await SchoolApiService.instance.deleteEmployee(emp.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Əməkdaş sistemdən silindi' : 'Silinmə zamanı xəta baş verdi'),
                    backgroundColor: success ? AppColors.emerald : AppColors.error,
                  ),
                );
                if (success) _loadEmployees();
              }
            },
            child: const Text('Bəli, Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _openEmployeeStoreScreen({Employee? employeeToEdit}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeStoreScreen(employeeToEdit: employeeToEdit),
      ),
    );
    if (result == true) {
      _loadEmployees();
    }
  }

  void _showEmployeeDetails(Employee emp, {required bool canEdit, required bool canDelete, required bool canViewSalary, required bool canViewContracts}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeProfileScreen(employee: emp),
      ),
    );
    _loadEmployees();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final appState = context.watch<AppState>();

    // Role-based permissions
    final isSuper = appState.isSuperAdmin;
    final canCreate = isSuper ||
        appState.hasPermission('gopanel.hr.employees.create') ||
        appState.hasPermission('add_employees');
    final canEdit = isSuper ||
        appState.hasPermission('gopanel.hr.employees.update') ||
        appState.hasPermission('edit_employees');
    final canDelete = isSuper ||
        appState.hasPermission('gopanel.hr.employees.delete') ||
        appState.hasPermission('delete_employees');
    final canViewSalary = isSuper ||
        appState.hasPermission('salary_calculator') ||
        appState.hasPermission('manage_payroll') ||
        appState.hasPermission('gopanel.finance.tax_rules.view');
    final canViewContracts = isSuper ||
        appState.hasPermission('view_contracts') ||
        appState.hasPermission('manage_contracts') ||
        appState.hasPermission('gopanel.hr.contracts.view');

    final employees = _filteredEmployees;
    final totalCount = _employees.length;
    final activeCount = _employees.where((e) => e.isActive).length;
    final inactiveCount = _employees.where((e) => !e.isActive).length;
    final activeTeachersCount = _employees.where((e) => e.isTeacher && e.isActive).length;
    final activeAdminCount = _employees.where((e) => !e.isTeacher && e.isActive).length;

    return Scaffold(
      backgroundColor: palette.bgBase,
      appBar: AppBar(
        title: const Text(
          'İnsan Resursları — Əməkdaşlar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.5),
        ),
        backgroundColor: AppColors.primary,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          if (canViewSalary)
            IconButton(
              tooltip: _hideSalaries ? 'Maaşları Göstər' : 'Maaşları Gizlət',
              icon: Icon(_hideSalaries ? Icons.visibility_off_rounded : Icons.visibility_rounded),
              onPressed: () => setState(() => _hideSalaries = !_hideSalaries),
            ),
          IconButton(
            tooltip: 'Yenilə',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadEmployees,
          ),
          if (canViewContracts)
            IconButton(
              tooltip: 'Müqavilələr',
              icon: const Icon(Icons.description_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ContractsScreen()),
              ),
            ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              backgroundColor: palette.brandRoyal,
              icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
              label: const Text(
                'Yeni Əməkdaş',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _openEmployeeStoreScreen(),
            )
          : null,
      body: ResponsiveCenter(
        child: RefreshIndicator(
          onRefresh: _loadEmployees,
          child: Column(
            children: [
              // Modern Executive KPI Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    // Overview Row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            palette.surface1,
                            palette.surface2,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: palette.borderHairline),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: palette.brandRoyal.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.groups_rounded, color: palette.brandRoyal, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Ümumi Heyət: ',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: palette.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '$totalCount nəfər',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: palette.brandRoyal,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Aktiv işləyən: $activeCount  •  Qeyri-aktiv: $inactiveCount',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: palette.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => setState(() => _selectedCategory = 'ALL'),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _selectedCategory == 'ALL'
                                    ? palette.brandRoyal
                                    : palette.surface3,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Hamısı',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _selectedCategory == 'ALL' ? Colors.white : palette.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 2 Prominent Category Cards
                    Row(
                      children: [
                        // Pedaqoji (Müəllimlər)
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() {
                              _selectedCategory = _selectedCategory == 'TEACHERS' ? 'ALL' : 'TEACHERS';
                            }),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _selectedCategory == 'TEACHERS'
                                    ? const Color(0xFF0F766E).withValues(alpha: 0.12)
                                    : palette.surface1,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedCategory == 'TEACHERS'
                                      ? const Color(0xFF0F766E)
                                      : palette.borderHairline,
                                  width: _selectedCategory == 'TEACHERS' ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0F766E).withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.school_rounded, size: 16, color: Color(0xFF0F766E)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Müəllimlər',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF0F766E),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '$activeTeachersCount nəfər',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF0F766E),
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
                        const SizedBox(width: 8),

                        // İnzibati Heyət
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() {
                              _selectedCategory = _selectedCategory == 'ADMIN' ? 'ALL' : 'ADMIN';
                            }),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _selectedCategory == 'ADMIN'
                                    ? const Color(0xFF7C3AED).withValues(alpha: 0.12)
                                    : palette.surface1,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedCategory == 'ADMIN'
                                      ? const Color(0xFF7C3AED)
                                      : palette.borderHairline,
                                  width: _selectedCategory == 'ADMIN' ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.business_center_rounded, size: 16, color: Color(0xFF7C3AED)),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'İnzibati Heyət',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF7C3AED),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '$activeAdminCount nəfər',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            color: Color(0xFF7C3AED),
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
                      ],
                    ),
                  ],
                ),
              ),

              // Search Bar & Filter Toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: AppSearchBar(
                        controller: _searchController,
                        hintText: 'Ad, soyad, FİN, vəzifə və ya fənn...',
                        onChanged: (_) => setState(() {}),
                        onClear: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => setState(() => _showAdvancedFilters = !_showAdvancedFilters),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: _showAdvancedFilters || _selectedFilial != 'Hamısı' || _selectedSector != 'Hamısı' || _selectedDepartment != 'Hamısı'
                              ? palette.brandRoyal
                              : palette.surface1,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _showAdvancedFilters ? palette.brandRoyal : palette.borderHairline,
                          ),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          size: 20,
                          color: _showAdvancedFilters || _selectedFilial != 'Hamısı' || _selectedSector != 'Hamısı' || _selectedDepartment != 'Hamısı'
                              ? Colors.white
                              : palette.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Quick Category Filter Chips Bar
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    _categoryFilterChip('ALL', 'Hamısı ($totalCount)'),
                    const SizedBox(width: 6),
                    _categoryFilterChip('TEACHERS', 'Müəllimlər ($activeTeachersCount)'),
                    const SizedBox(width: 6),
                    _categoryFilterChip('ADMIN', 'İnzibati ($activeAdminCount)'),
                    const SizedBox(width: 6),
                    _categoryFilterChip('INACTIVE', 'Qeyri-aktiv ($inactiveCount)'),
                  ],
                ),
              ),

              // Optional Expandable Sub-Filter Row: Filial & Sector & Department
              if (_showAdvancedFilters) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      // Filial Selector
                      Expanded(
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: palette.surface1,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: palette.borderHairline),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedFilial,
                              isExpanded: true,
                              icon: const Icon(Icons.arrow_drop_down, size: 20),
                              style: TextStyle(fontSize: 12, color: palette.textPrimary, fontWeight: FontWeight.w600),
                              items: _filials.map((f) {
                                return DropdownMenuItem<String>(
                                  value: f,
                                  child: Text(f, overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedFilial = val);
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Sector Selector
                      Expanded(
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: palette.surface1,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: palette.borderHairline),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedSector,
                              isExpanded: true,
                              icon: const Icon(Icons.arrow_drop_down, size: 20),
                              style: TextStyle(fontSize: 12, color: palette.textPrimary, fontWeight: FontWeight.w600),
                              items: _sectors.map((s) {
                                return DropdownMenuItem<String>(
                                  value: s,
                                  child: Text('Bölmə: $s', overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedSector = val);
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Department Horizontal Scroll
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _dynamicDepartments.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final dept = _dynamicDepartments[index];
                      final isSelected = dept == _selectedDepartment;
                      return ChoiceChip(
                        label: Text(dept),
                        selected: isSelected,
                        onSelected: (val) {
                          if (val) setState(() => _selectedDepartment = dept);
                        },
                        selectedColor: palette.brandRoyal,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : palette.textPrimary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 11.5,
                        ),
                        backgroundColor: palette.surface1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          side: BorderSide(
                            color: isSelected ? palette.brandRoyal : palette.borderHairline,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 6),

              // List Header count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'Göstərilən əməkdaşlar: ${employees.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: palette.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    if (_isLoading)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),

              // Employee List
              Expanded(
                child: _isLoading && _employees.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : employees.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_search_rounded,
                                  size: 60,
                                  color: palette.textTertiary.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Axtarışa uyğun əməkdaş tapılmadı',
                                  style: TextStyle(
                                    color: palette.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                            itemCount: employees.length,
                            itemBuilder: (context, index) {
                              final emp = employees[index];
                              return _buildEmployeeCard(
                                emp,
                                palette,
                                canEdit: canEdit,
                                canDelete: canDelete,
                                canViewSalary: canViewSalary,
                                canViewContracts: canViewContracts,
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryFilterChip(String key, String title) {
    final palette = AppPalette.of(context);
    final isSelected = _selectedCategory == key;
    return InkWell(
      onTap: () => setState(() => _selectedCategory = key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 14),
        decoration: BoxDecoration(
          color: isSelected ? palette.brandRoyal : palette.surface1,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? palette.brandRoyal : palette.borderHairline,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          maxLines: 1,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : palette.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _statPill(String title, String val, IconData icon, Color color, AppPalette palette) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.borderHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 9.5, color: palette.textSecondary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            val,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(
    Employee emp,
    AppPalette palette, {
    required bool canEdit,
    required bool canDelete,
    required bool canViewSalary,
    required bool canViewContracts,
  }) {
    final isTeacher = emp.isTeacher;
    final hasSalary = canViewSalary && emp.salary > 0;

    return ModernCard(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: () => _showEmployeeDetails(
        emp,
        canEdit: canEdit,
        canDelete: canDelete,
        canViewSalary: canViewSalary,
        canViewContracts: canViewContracts,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Avatar, Name, Badges
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with Active/Inactive dot
              Stack(
                children: [
                  CircleAvatar(
                    radius: 23,
                    backgroundColor: isTeacher
                        ? const Color(0xFF0F766E).withValues(alpha: 0.12)
                        : palette.brandRoyal.withValues(alpha: 0.12),
                    child: Text(
                      emp.firstName.isNotEmpty ? emp.firstName[0].toUpperCase() : 'Ə',
                      style: TextStyle(
                        color: isTeacher ? const Color(0xFF0F766E) : palette.brandRoyal,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: emp.isActive ? AppColors.emerald : AppColors.gold,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Name, Father name, Position
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Tags: Code, FIN, Filial
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: palette.brandRoyal.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            emp.code,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: palette.brandRoyal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'FİN: ${emp.finCode}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        if (emp.filial != null && emp.filial!.isNotEmpty) ...[
                          const SizedBox(width: 5),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                emp.filial!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  color: Colors.blueGrey.shade700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Full Name
                    Text(
                      emp.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        height: 1.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),

                    if (emp.fatherName.isNotEmpty)
                      Text(
                        'Ata adı: ${emp.fatherName}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: palette.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Department & Position row
          Row(
            children: [
              const Icon(Icons.apartment_rounded, size: 13, color: Color(0xFF2563EB)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  emp.department,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Text('•', style: TextStyle(color: Colors.grey)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  emp.position,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Teacher Classes or Sector badge if applicable
          if (isTeacher && emp.subject.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.menu_book_rounded, size: 12, color: Color(0xFF0F766E)),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Fənn: ${emp.subject}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F766E),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (emp.assignedClasses.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${emp.assignedClasses.length} sinif',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                    ),
                  ),
                ],
              ],
            ),
          ],

          // Salary Badge (if allowed and not hidden)
          if (hasSalary) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.payments_outlined, size: 13, color: Colors.green.shade800),
                  const SizedBox(width: 5),
                  Text(
                    _hideSalaries
                        ? 'Əməkhaqqı: •••••• AZN'
                        : 'Maaş: ${emp.salary.toStringAsFixed(0)} AZN (Net: ${emp.netSalary > 0 ? emp.netSalary.toStringAsFixed(0) : (emp.salary * 0.875).toStringAsFixed(0)} AZN)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Divider(height: 18),

          // Action Buttons Bottom Row
          Row(
            children: [
              // View Details Button (Flexible)
              Flexible(
                child: InkWell(
                  onTap: () => _showEmployeeDetails(
                    emp,
                    canEdit: canEdit,
                    canDelete: canDelete,
                    canViewSalary: canViewSalary,
                    canViewContracts: canViewContracts,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: palette.brandRoyal.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.badge_outlined, size: 14, color: palette.brandRoyal),
                        const SizedBox(width: 4),
                        const Flexible(
                          child: Text(
                            'Profil & Sənədlər',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // Phone Call button
              if (emp.phone.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.phone_outlined, size: 18, color: Colors.teal),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Zəng et: ${emp.phone}',
                  onPressed: () => _makePhoneCall(emp.phone),
                ),

              // Email button
              if (emp.email.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.email_outlined, size: 18, color: Colors.blueAccent),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Email göndər: ${emp.email}',
                  onPressed: () => _sendEmail(emp.email),
                ),

              // Edit button
              if (canEdit)
                IconButton(
                  icon: const Icon(Icons.edit_note_rounded, size: 20, color: AppColors.primaryAccent),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Redaktə et',
                  onPressed: () => _openEmployeeStoreScreen(employeeToEdit: emp),
                ),

              // Delete button (Only for superadmin/director)
              if (canDelete)
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Sil',
                  onPressed: () => _confirmDeleteEmployee(emp),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// =================================================================
// EMPLOYEE DETAIL MODAL (Multi-Tab Comprehensive Profile)
// =================================================================

class _EmployeeDetailModal extends StatefulWidget {
  final Employee employee;
  final bool canEdit;
  final bool canDelete;
  final bool canViewSalary;
  final bool canViewContracts;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EmployeeDetailModal({
    required this.employee,
    required this.canEdit,
    required this.canDelete,
    required this.canViewSalary,
    required this.canViewContracts,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_EmployeeDetailModal> createState() => _EmployeeDetailModalState();
}

class _EmployeeDetailModalState extends State<_EmployeeDetailModal> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    return DateFormat('dd.MM.yyyy').format(dt);
  }

  String _calcExperience(DateTime? hireDate) {
    if (hireDate == null) return '-';
    final now = DateTime.now();
    var months = (now.year - hireDate.year) * 12 + now.month - hireDate.month;
    if (now.day < hireDate.day) months--;
    if (months < 0) months = 0;
    final years = months ~/ 12;
    final remMonths = months % 12;
    if (years > 0 && remMonths > 0) return '$years il $remMonths ay';
    if (years > 0) return '$years il';
    return '$months ay';
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final emp = widget.employee;
    final isTeacher = emp.isTeacher;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: palette.borderHairline),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: palette.textTertiary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),

            // Profile Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: isTeacher
                        ? const Color(0xFF0F766E).withValues(alpha: 0.15)
                        : palette.brandRoyal.withValues(alpha: 0.15),
                    child: Text(
                      emp.firstName.isNotEmpty ? emp.firstName[0].toUpperCase() : 'Ə',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isTeacher ? const Color(0xFF0F766E) : palette.brandRoyal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emp.fullName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (emp.fatherName.isNotEmpty)
                          Text(
                            'Ata adı: ${emp.fatherName}',
                            style: TextStyle(fontSize: 12, color: palette.textSecondary),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            StatusBadge(
                              label: emp.isActive ? 'Aktiv İşçi' : 'Qeyri-aktiv',
                              color: emp.isActive ? AppColors.emerald : AppColors.gold,
                              fontSize: 10,
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: palette.brandRoyal.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                emp.code,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: palette.brandRoyal),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Tab bar
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: palette.borderHairline)),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: palette.brandRoyal,
                unselectedLabelColor: palette.textSecondary,
                indicatorColor: palette.brandRoyal,
                labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'Şəxsi & Əlaqə'),
                  Tab(text: 'İş & Təhsil'),
                  Tab(text: 'Müqavilə & Maliyyə'),
                  Tab(text: 'Sistem & Rollar'),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Personal & Contact
                  ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _sectionTitle('Şəxsi Kimlik Məlumatları', Icons.badge_outlined, palette),
                      _infoRow('FİN Kod', emp.finCode, palette),
                      _infoRow('Ş/V Seriya və Nömrəsi', emp.idCardSerial.isNotEmpty ? emp.idCardSerial : '-', palette),
                      _infoRow('Cinsiyyət', emp.gender, palette),
                      _infoRow('Doğum Tarixi', _formatDate(emp.birthDate), palette),
                      _infoRow('Qan Qrupu', emp.bloodGroup.isNotEmpty ? emp.bloodGroup : '-', palette),
                      _infoRow('Ailə Vəziyyəti', emp.maritalStatus.isNotEmpty ? emp.maritalStatus : '-', palette),
                      const SizedBox(height: 16),
                      _sectionTitle('Əlaqə və Ünvan', Icons.contact_phone_outlined, palette),
                      _infoRow('Əlaqə Telefonu', emp.phone.isNotEmpty ? emp.phone : '-', palette),
                      if (emp.corporatePhone != null && emp.corporatePhone!.isNotEmpty)
                        _infoRow('Korporativ Telefon', emp.corporatePhone!, palette),
                      _infoRow('Elektron Poçt', emp.email.isNotEmpty ? emp.email : '-', palette),
                      _infoRow('Qeydiyyat / Faktiki Ünvan', emp.address.isNotEmpty ? emp.address : '-', palette),
                    ],
                  ),

                  // Tab 2: Job & Education
                  ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _sectionTitle('Vəzifə və Struktur', Icons.business_center_outlined, palette),
                      _infoRow('Struktur / Departament', emp.department, palette),
                      _infoRow('Vəzifə', emp.position, palette),
                      _infoRow('Filial', emp.filial ?? 'Bakı filialı', palette),
                      _infoRow('Tədris Bölməsi', emp.sector ?? 'Azərbaycan', palette),
                      _infoRow('İşə Qəbul Tarixi', _formatDate(emp.hireDate), palette),
                      _infoRow('Ümumi İş Stajı', _calcExperience(emp.hireDate), palette),
                      const SizedBox(height: 16),
                      _sectionTitle('Təhsil və İxtisas', Icons.school_outlined, palette),
                      _infoRow('Təhsil Dərəcəsi', emp.educationLevel.isNotEmpty ? emp.educationLevel : '-', palette),
                      _infoRow('Ali Təhsil Müəssisəsi', emp.university.isNotEmpty ? emp.university : '-', palette),
                      _infoRow('İxtisas', emp.specialty.isNotEmpty ? emp.specialty : '-', palette),
                      if (isTeacher) ...[
                        const SizedBox(height: 16),
                        _sectionTitle('Pedaqoji Yük və Tədris', Icons.menu_book_outlined, palette),
                        _infoRow('Əsas Tədris Fənni', emp.subject.isNotEmpty ? emp.subject : '-', palette),
                        _infoRow(
                          'Təhkim Olunmuş Siniflər',
                          emp.assignedClasses.isNotEmpty ? emp.assignedClasses.join(', ') : 'Sinif yoxdur',
                          palette,
                        ),
                      ],
                    ],
                  ),

                  // Tab 3: Contract & Financial
                  ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _sectionTitle('Əmək Müqaviləsi', Icons.description_outlined, palette),
                      _infoRow('Müqavilə Nömrəsi', emp.contractNumber.isNotEmpty ? emp.contractNumber : (emp.contractId != null ? 'MÜQ-${emp.contractId}' : '-'), palette),
                      _infoRow('Müqavilə Növü', emp.contractType == 'fixed' ? 'Müddətli' : 'Müddətsiz', palette),
                      if (emp.contractStartDate != null)
                        _infoRow('Qüvvəyə Minmə Tarixi', emp.contractStartDate!, palette),
                      if (emp.contractEndDate != null)
                        _infoRow('Bitmə Tarixi', emp.contractEndDate!, palette),
                      const SizedBox(height: 16),
                      _sectionTitle('Maliyyə və Əməkhaqqı', Icons.payments_outlined, palette),
                      if (widget.canViewSalary) ...[
                        _infoRow('Təyin Olunmuş Gross Maaş', '${emp.salary.toStringAsFixed(2)} AZN', palette),
                        _infoRow('Təxmini Net Maaş', '${emp.netSalary > 0 ? emp.netSalary.toStringAsFixed(2) : (emp.salary * 0.875).toStringAsFixed(2)} AZN', palette),
                      ] else
                        _infoRow('Əməkhaqqı', 'Məxfi (Yalnız Maliyyə və HR üçün açıqdır)', palette),
                      const SizedBox(height: 16),
                      _sectionTitle('Bank Rekvizitləri', Icons.account_balance_outlined, palette),
                      _infoRow('Bank Adı', emp.bankName.isNotEmpty ? emp.bankName : '-', palette),
                      _infoRow('Hesab Nömrəsi', emp.bankAccount.isNotEmpty ? emp.bankAccount : '-', palette),
                      _infoRow('IBAN', emp.bankIban.isNotEmpty ? emp.bankIban : '-', palette),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          if (widget.canViewSalary)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SalaryCalculatorScreen(
                                        initialGrossSalary: emp.salary,
                                        employeeName: emp.fullName,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.calculate_rounded, size: 16),
                                label: const Text('Maaş Hesabla', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          if (widget.canViewSalary && widget.canViewContracts)
                            const SizedBox(width: 10),
                          if (widget.canViewContracts) ...[
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ContractsScreen(
                                        employeeId: emp.id,
                                        employeeCode: emp.code,
                                        employeeName: emp.fullName,
                                        autoOpenFirstContract: true,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.history_edu_rounded, size: 16),
                                label: const Text('Müqavilələr', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EmployeeDocumentsScreen(
                                        employeeId: emp.id,
                                        employeeName: emp.fullName,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.description_rounded, size: 16),
                                label: const Text('Sənədlər', style: TextStyle(fontSize: 12)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),

                  // Tab 4: System & Roles
                  ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _sectionTitle('İstifadəçi Hesabı və Giriş', Icons.security_outlined, palette),
                      _infoRow('Sistem FİN Kodu', emp.finCode, palette),
                      _infoRow('Giriş E-poçtu', emp.email.isNotEmpty ? emp.email : '-', palette),
                      _infoRow('Status', emp.isActive ? 'Aktiv (Giriş icazəsi var)' : 'Deaktiv edilib', palette),
                      const SizedBox(height: 16),
                      _sectionTitle('Təhkim Olunmuş Rollar', Icons.admin_panel_settings_outlined, palette),
                      if (emp.roles.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: emp.roles.map((r) {
                            return Chip(
                              label: Text(r, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              backgroundColor: palette.brandRoyal.withValues(alpha: 0.1),
                              side: BorderSide(color: palette.brandRoyal.withValues(alpha: 0.3)),
                            );
                          }).toList(),
                        )
                      else
                        Text(
                          'Sistem rolu təyin edilməyib (Standart İstifadəçi)',
                          style: TextStyle(color: palette.textSecondary, fontSize: 13),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom action bar (Edit & Delete if authorized)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: palette.surface1,
                border: Border(top: BorderSide(color: palette.borderHairline)),
              ),
              child: Row(
                children: [
                  if (widget.canDelete)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error),
                      ),
                      onPressed: widget.onDelete,
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: const Text('Sil'),
                    ),
                  const Spacer(),
                  if (widget.canEdit)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: palette.brandRoyal),
                      onPressed: widget.onEdit,
                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                      label: const Text('Məlumatları Redaktə Et'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon, AppPalette palette) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 17, color: palette.brandRoyal),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: palette.brandRoyal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, AppPalette palette) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(fontSize: 12.5, color: palette.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 6,
            child: Text(
              value,
              style: TextStyle(fontSize: 12.5, color: palette.textPrimary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
