import '../../../core/services/school_api_service.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/responsive.dart';
import '../../../data/models/finance_model.dart';
import 'finance_dictionary_screen.dart';

class GeneralLedgerScreen extends StatefulWidget {
  const GeneralLedgerScreen({super.key});

  @override
  State<GeneralLedgerScreen> createState() => _GeneralLedgerScreenState();
}

class _GeneralLedgerScreenState extends State<GeneralLedgerScreen> {
  String _selectedType = 'Hamısı';

  @override
  void initState() {
    super.initState();
    _loadRealLedger();
  }

  Future<void> _loadRealLedger() async {
    final rows = await SchoolApiService.instance.fetchLedger();
    if (rows.isNotEmpty && mounted) {
      setState(() {
        _transactions
          ..clear()
          ..addAll(rows.map((r) => FinanceLedgerItem(
            id: r['id']?.toString() ?? 'tx-1',
            transactionNumber: r['transactionNumber']?.toString() ?? 'TX',
            type: r['type']?.toString() ?? 'income',
            category: r['category']?.toString() ?? 'Təhsil Haqqı',
            title: r['title']?.toString() ?? 'Ödəniş',
            amount: (r['amount'] as num?)?.toDouble() ?? 0.0,
            date: DateTime.tryParse(r['date']?.toString() ?? '') ?? DateTime.now(),
            paymentMethod: r['paymentMethod']?.toString() ?? 'Nağd / Bank',
            counterparty: r['counterparty']?.toString() ?? 'Valideyn',
            description: r['description']?.toString() ?? '',
          )));
      });
    }
  }

  final List<FinanceLedgerItem> _transactions = [
    FinanceLedgerItem(
      id: 'tx-1',
      transactionNumber: 'TX-2026-8801',
      type: 'income',
      category: 'Təhsil Haqqı',
      title: '10-A sinif təhsil haqqı ödənişi',
      amount: 4500.0,
      date: DateTime(2026, 10, 28),
      paymentMethod: 'Bank köçürməsi',
      counterparty: 'Rauf Əliyev',
      description: 'Murad Əliyev üçün 1-ci yarımil ödənişi',
    ),
    FinanceLedgerItem(
      id: 'tx-2',
      transactionNumber: 'TX-2026-8802',
      type: 'expense',
      category: 'Əməkhaqqı Fondu',
      title: 'Pedaqoji heyət oktyabr maaş ödənişi',
      amount: 14200.0,
      date: DateTime(2026, 10, 31),
      paymentMethod: 'Bank kartı',
      counterparty: 'İdrak Liseyi İşçi Heyəti',
      description: '2026 Oktyabr ayı xalis əməkhaqqı köçürməsi',
    ),
    FinanceLedgerItem(
      id: 'tx-3',
      transactionNumber: 'TX-2026-8803',
      type: 'income',
      category: 'Yeməkxana və Kafe',
      title: 'Aylıq yeməkxana rasion gəlirləri',
      amount: 3250.0,
      date: DateTime(2026, 10, 29),
      paymentMethod: 'Onlayn Kart',
      counterparty: 'Valideynlər Şurası',
      description: 'Oktyabr ayı nahar abunəlikləri',
    ),
    FinanceLedgerItem(
      id: 'tx-4',
      transactionNumber: 'TX-2026-8804',
      type: 'expense',
      category: 'Kommunal və Təsərrüfat',
      title: 'İstilik və Elektrik enerjisi təminatı',
      amount: 1850.0,
      date: DateTime(2026, 10, 25),
      paymentMethod: 'Bank köçürməsi',
      counterparty: 'Azərişıq ASC / Azəriqaz İB',
      description: 'Məktəb binası kommunal xidmətlər',
    ),
    FinanceLedgerItem(
      id: 'tx-5',
      transactionNumber: 'TX-2026-8805',
      type: 'expense',
      category: 'İT və Proqram Təminatı',
      title: 'Server və Şəbəkə İllik Lisenziyası',
      amount: 980.0,
      date: DateTime(2026, 10, 20),
      paymentMethod: 'Bank köçürməsi',
      counterparty: 'Cloud & Domain Provider',
      description: 'Məktəb idarəetmə platforması lisenziyası',
    ),
  ];

  final List<String> _types = ['Hamısı', 'Mədaxil (Gəlir)', 'Məxaric (Xərc)'];

  List<FinanceLedgerItem> get _filteredTransactions {
    return _transactions.where((tx) {
      return switch (_selectedType) {
        'Mədaxil (Gəlir)' => tx.isIncome,
        'Məxaric (Xərc)' => !tx.isIncome,
        _ => true,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final txList = _filteredTransactions;

    final totalIncome = _transactions
        .where((t) => t.isIncome)
        .fold<double>(0.0, (acc, t) => acc + t.amount);
    final totalExpense = _transactions
        .where((t) => !t.isIncome)
        .fold<double>(0.0, (acc, t) => acc + t.amount);
    final netBalance = totalIncome - totalExpense;

    return Scaffold(
      backgroundColor: palette.bgBase,
      appBar: AppBar(        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Baş Maliyyə Jurnalı (Ledger)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Maliyyə Kateqoriyaları',
            icon: const Icon(Icons.category_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FinanceDictionaryScreen()),
            ),
          ),
        ],),
      body: ResponsiveCenter(
        child: Column(
          children: [
            // Net Balance Big Card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [palette.brandRoyal, palette.brandAzure],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: palette.brandRoyal.withValues(alpha: 0.22),
                      blurRadius: 16,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ÜMUMİ MƏKTƏB XALİS BALANSI',
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${netBalance.toStringAsFixed(2)} AZN',
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Mədaxil (Gəlir)', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                Text(
                                  '+${totalIncome.toInt()} AZN',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Məxaric (Xərc)', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                Text(
                                  '-${totalExpense.toInt()} AZN',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _types.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final t = _types[index];
                    final isSelected = t == _selectedType;
                    return ChoiceChip(
                      label: Text(t),
                      selected: isSelected,
                      onSelected: (val) {
                        if (val) setState(() => _selectedType = t);
                      },
                      selectedColor: palette.brandRoyal,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : palette.textPrimary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 12,
                      ),
                      backgroundColor: palette.surface1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        side: BorderSide(color: isSelected ? palette.brandRoyal : palette.borderHairline),
                      ),
                    );
                  },
                ),
              ),
            ),

            SectionHeader(
              title: 'Əməliyyatlar Jurnalı',
              subtitle: '${txList.length} maliyyə əməliyyatı',
            ),

            // Ledger List
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: txList.length,
                itemBuilder: (context, index) {
                  final tx = txList[index];
                  final isIncome = tx.isIncome;
                  final amountColor = isIncome ? AppColors.emerald : AppColors.rose;

                  return ModernCard(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: amountColor.withValues(alpha: 0.12),
                          child: Icon(
                            isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            color: amountColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${tx.category}  •  ${_formatDate(tx.date)}',
                                style: TextStyle(color: palette.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              if (tx.counterparty.isNotEmpty)
                                Text(
                                  tx.counterparty,
                                  style: TextStyle(color: palette.textTertiary, fontSize: 11),
                                ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${isIncome ? '+' : '-'}${tx.amount.toStringAsFixed(2)} AZN',
                              style: TextStyle(
                                color: amountColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                            StatusBadge(
                              label: tx.paymentMethod,
                              color: palette.brandRoyal,
                              fontSize: 9,
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}
