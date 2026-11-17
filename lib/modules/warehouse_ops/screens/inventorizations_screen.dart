import '../../../core/services/school_api_service.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/modern_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/responsive.dart';
import '../../../data/models/warehouse_ops_model.dart';
import 'canteen_supply_screen.dart';

class InventorizationsScreen extends StatefulWidget {
  const InventorizationsScreen({super.key});

  @override
  State<InventorizationsScreen> createState() => _InventorizationsScreenState();
}

class _InventorizationsScreenState extends State<InventorizationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Hamısı';

  @override
  void initState() {
    super.initState();
    _loadRealWarehouse();
  }

  Future<void> _loadRealWarehouse() async {
    final rows = await SchoolApiService.instance.fetchWarehouseItems();
    if (rows.isNotEmpty && mounted) {
      setState(() {
        _items
          ..clear()
          ..addAll(rows.map((r) => WarehouseInventoryItem(
            id: r['id']?.toString() ?? 'inv-1',
            code: r['code']?.toString() ?? 'ANB',
            name: r['name']?.toString() ?? 'Anbar Məhsulu',
            category: r['category']?.toString() ?? 'Ofis avadanlığı',
            quantity: (r['quantity'] as num?)?.toDouble() ?? 0.0,
            unit: r['unit']?.toString() ?? 'ədəd',
            minThreshold: (r['minThreshold'] as num?)?.toDouble() ?? 5.0,
            unitPrice: (r['unitPrice'] as num?)?.toDouble() ?? 0.0,
            location: r['location']?.toString() ?? 'Əsas Anbar',
            lastAuditedDate: DateTime.tryParse(r['lastAuditedDate']?.toString() ?? '') ?? DateTime.now(),
            notes: r['notes']?.toString() ?? '',
          )));
      });
    }
  }

  final List<WarehouseInventoryItem> _items = [
    WarehouseInventoryItem(
      id: 'inv-1',
      code: 'ANB-1001',
      name: 'A4 Kağız (Double A 80g 500 vərəq)',
      category: 'Ofis avadanlığı',
      quantity: 120.0,
      unit: 'qutu',
      minThreshold: 30.0,
      unitPrice: 8.50,
      location: 'Əsas Anbar, Rəf A-2',
      lastAuditedDate: DateTime(2026, 10, 25),
      notes: 'Tədris şöbəsi üçün nəzərdə tutulub',
    ),
    WarehouseInventoryItem(
      id: 'inv-2',
      code: 'ANB-1002',
      name: 'Ağıllı Lövhə Markerləri (4 rəngli dəst)',
      category: 'Tədris ləvazimatı',
      quantity: 8.0,
      unit: 'dəst',
      minThreshold: 15.0,
      unitPrice: 12.00,
      location: 'Əsas Anbar, Rəf B-1',
      lastAuditedDate: DateTime(2026, 10, 25),
      notes: 'Ehtiyat kritik həddə çatıb, yeni sifariş tələb olunur',
    ),
    WarehouseInventoryItem(
      id: 'inv-3',
      code: 'ANB-1003',
      name: 'Şagird Partası və Oturacağı (Tənzimlənən)',
      category: 'Mebel',
      quantity: 45.0,
      unit: 'dəst',
      minThreshold: 10.0,
      unitPrice: 110.00,
      location: 'Mebel Anbarı, Bölmə C',
      lastAuditedDate: DateTime(2026, 10, 20),
      notes: 'İbtidai korpus üçün ehtiyat',
    ),
    WarehouseInventoryItem(
      id: 'inv-4',
      code: 'ANB-1004',
      name: 'Dezinfeksiya Mayesi və Təmizlik Dəsti',
      category: 'Təsərrüfat',
      quantity: 2.0,
      unit: 'qutu',
      minThreshold: 10.0,
      unitPrice: 45.00,
      location: 'Təsərrüfat Zirzəmisi',
      lastAuditedDate: DateTime(2026, 10, 28),
      notes: 'Təcili təchizatçıdan sifariş verilməlidir',
    ),
    WarehouseInventoryItem(
      id: 'inv-5',
      code: 'ANB-1005',
      name: 'Futbol və Voleybol Topları (Mikasa)',
      category: 'Tədris ləvazimatı',
      quantity: 30.0,
      unit: 'ədəd',
      minThreshold: 8.0,
      unitPrice: 35.00,
      location: 'İdman Zalı Anbarı',
      lastAuditedDate: DateTime(2026, 10, 15),
      notes: 'Bədən tərbiyəsi dərsləri üçün',
    ),
  ];

  final List<String> _categories = [
    'Hamısı',
    'Tədris ləvazimatı',
    'Ofis avadanlığı',
    'Mebel',
    'Təsərrüfat',
  ];

  List<WarehouseInventoryItem> get _filteredItems {
    final query = _searchController.text.trim().toLowerCase();
    return _items.where((item) {
      final matchesCategory = _selectedCategory == 'Hamısı' || item.category == _selectedCategory;
      final matchesSearch = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.code.toLowerCase().contains(query) ||
          item.location.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lowStockCount = _items.where((item) => item.isLowStock).length;
    final totalValue = _items.fold<double>(0.0, (acc, item) => acc + (item.quantity * item.unitPrice));

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Anbar və İnventarizasiya'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.restaurant_menu),
            tooltip: 'Yeməkxana Təchizatı',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CanteenSupplyScreen()),
              );
            },
          ),
        ],),
      body: ResponsiveCenter(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            ModernCard(
              gradient: LinearGradient(
                colors: [
                  AppPalette.primary.withValues(alpha: 0.85),
                  AppPalette.primaryDark,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Məktəb Əsas Anbarı',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_items.length} nomenklatura qeydiyyatdadır',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: AppRadius.smRadius,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                '${totalValue.toStringAsFixed(0)} ₼',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text('Ümumi Dəyər', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                          Container(width: 1, height: 24, color: Colors.white30),
                          Column(
                            children: [
                              Text(
                                '$lowStockCount ədəd',
                                style: TextStyle(
                                  color: lowStockCount > 0 ? Colors.orangeAccent : Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Text('Kritik Qalıq', style: TextStyle(color: Colors.white70, fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppSearchBar(
              hintText: 'Məhsul adı və ya inventar kodu ilə axtarış...',
              onChanged: (_) => setState(() {}),
              controller: _searchController,
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedCategory = cat);
                      },
                      selectedColor: AppPalette.primary.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: isSelected ? AppPalette.primary : AppColors.getTextSecondary(context),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            SectionHeader(
              title: 'İnventar Qeydləri',
              trailing: '${_filteredItems.length} məhsul',
            ),
            const SizedBox(height: 8),
            if (_filteredItems.isEmpty)
              ModernCard(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 48, color: AppColors.getTextSecondary(context)),
                      const SizedBox(height: 12),
                      Text(
                        'Axtarışa uyğun inventar tapılmadı',
                        style: TextStyle(color: AppColors.getTextSecondary(context)),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._filteredItems.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ModernCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: (item.isLowStock ? AppColors.warning : AppPalette.primary)
                                      .withValues(alpha: 0.1),
                                  borderRadius: AppRadius.smRadius,
                                ),
                                child: Icon(
                                  item.isLowStock ? Icons.warning_amber_rounded : Icons.inventory,
                                  color: item.isLowStock ? AppColors.warning : AppPalette.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.getTextPrimary(context),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Kod: ${item.code} • ${item.category}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.getTextSecondary(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              StatusBadge(
                                label: item.isLowStock ? 'Kritik Qalıq' : 'Kifayət qədər',
                                color: item.isLowStock ? AppColors.warning : AppColors.success,
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mövcud Say',
                                    style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(context)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.quantity.toInt()} ${item.unit}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: item.isLowStock ? AppColors.error : AppColors.getTextPrimary(context),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Vahid Qiyməti',
                                    style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(context)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.unitPrice.toStringAsFixed(2)} ₼',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.getTextPrimary(context),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Məkan',
                                    style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(context)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.location,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.getTextSecondary(context),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (item.notes.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.getSurface(context),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, size: 14, color: AppColors.getTextSecondary(context)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      item.notes,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.getTextSecondary(context),
                                      ),
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
                );
              }),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
