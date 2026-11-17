import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:idrak_liseyi/data/models/employee_model.dart';
import 'package:idrak_liseyi/modules/hr/screens/contracts_screen.dart';
import 'package:idrak_liseyi/providers/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EmployeeContract model tests', () {
    test('parses all Web GoPanel fields correctly', () {
      final json = {
        'id': '101',
        'employee_id': '45',
        'employee_name': 'Əli Həsənov',
        'employee_code': 'IDR-045',
        'employee_fin': 'ABC1234',
        'contract_number': 'MÜQ-2024-001',
        'contract_type': 'indefinite',
        'start_date': '2024-09-01',
        'gross_salary': 1800.0,
        'net_salary': 1575.0,
        'salary_supplement': 150.0,
        'food_allowance': 80.0,
        'work_condition_supplement': 50.0,
        'status': 'active',
        'is_active': true,
        'position_title': 'Riyaziyyat Müəllimi',
        'department': 'Tədris Şöbəsi',
        'filial': 'Bakı filialı',
        'company': 'İdrak Liseyi MMC',
        'work_hours': 36.0,
        'notes': 'Əsas müqavilə',
        'cost_center': 'Mərkəz 01',
        'teqvim': '5 günlük təqvim',
        'work_schedule': '09:00 - 17:00',
        'work_regime': 'Standart rejim',
        'job_description': 'Dərslərin tədrisi',
        'trial_period_value': 3,
        'trial_period_unit': 'month',
        'base_vacation_days': 30,
        'position_id': 12,
        'structure_id': 5,
        'filial_id': 1,
        'company_id': 1,
        'teqvim_id': 2,
      };

      final contract = EmployeeContract.fromJson(json);

      expect(contract.id, '101');
      expect(contract.employeeName, 'Əli Həsənov');
      expect(contract.isIndefinite, isTrue);
      expect(contract.grossSalary, 1800.0);
      expect(contract.netSalary, 1575.0);
      expect(contract.salarySupplement, 150.0);
      expect(contract.foodAllowance, 80.0);
      expect(contract.costCenter, 'Mərkəz 01');
      expect(contract.teqvim, '5 günlük təqvim');
      expect(contract.trialPeriodValue, 3);
      expect(contract.trialPeriodUnit, 'month');
      expect(contract.baseVacationDays, 30);
      expect(contract.positionId, 12);
      expect(contract.structureId, 5);
      expect(contract.filialId, 1);
      expect(contract.companyId, 1);
      expect(contract.teqvimId, 2);
    });

    test('remainingText calculates indefinite properly', () {
      final contract = EmployeeContract(
        id: '1',
        employeeId: '10',
        employeeName: 'Test',
        contractNumber: 'M-1',
        contractType: 'indefinite',
        startDate: DateTime(2024, 1, 1),
        grossSalary: 1000,
        netSalary: 875,
        positionTitle: 'Müəllim',
      );

      expect(contract.isIndefinite, isTrue);
      expect(contract.remainingText, 'Müddətsiz müqavilə');
    });
  });

  group('ContractsScreen widget tests', () {
    testWidgets('renders contract detail sheet without overflow', (tester) async {
      final contract = EmployeeContract(
        id: '1',
        employeeId: '10',
        employeeName: 'Məmməd Əliyev',
        employeeCode: 'EMP-01',
        employeeFin: '7XYZ123',
        contractNumber: 'MÜQ-2024-99',
        contractType: 'fixed',
        startDate: DateTime(2024, 9, 1),
        endDate: DateTime(2025, 8, 31),
        grossSalary: 2500.0,
        netSalary: 2187.5,
        foodAllowance: 100.0,
        salarySupplement: 200.0,
        workConditionSupplement: 100.0,
        positionTitle: 'İnformatika Müəllimi',
        department: 'İT Şöbəsi',
        filial: 'Gəncə filialı',
        company: 'İdrak',
        costCenter: 'IT-01',
        teqvim: 'Əsas təqvim',
        workSchedule: '09:00 - 18:00',
        workRegime: 'Həftəlik 40 saatlıq iş rejimi',
        jobDescription: 'Liseyin proqram təminatı və dərs prosesi',
        trialPeriodValue: 3,
        trialPeriodUnit: 'ay',
        baseVacationDays: 28,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => Center(
                child: ElevatedButton(
                  onPressed: () => showEmployeeContractDetailSheet(ctx, contract),
                  child: const Text('Open Detail'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Detail'));
      await tester.pumpAndSettle();

      expect(find.text('Məmməd Əliyev'), findsOneWidget);
      expect(find.text('İnformatika Müəllimi'), findsOneWidget);
      expect(find.text('MÜQ-2024-99'), findsOneWidget);
      expect(find.text('2500.00 AZN'), findsOneWidget);
      expect(find.text('Vergi Hesabla'), findsOneWidget);
    });

    testWidgets('renders contract list item on narrow screen (360px) without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppState>(create: (_) => AppState()),
          ],
          child: const MaterialApp(
            home: ContractsScreen(),
          ),
        ),
      );

      await tester.pump();
      // Verify no assertion error or render overflow on narrow screens
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders contract action buttons in Wrap without overflow on 320px width', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4.5),
                      child: const Text('Sənədlər'),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4.5),
                      child: const Text('Düzəliş'),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4.5),
                      child: const Text('Vergi'),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4.5),
                      child: const Text('Xitam'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Sənədlər'), findsOneWidget);
      expect(find.text('Düzəliş'), findsOneWidget);
      expect(find.text('Vergi'), findsOneWidget);
      expect(find.text('Xitam'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
