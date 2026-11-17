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

class CanteenSupplyScreen extends StatefulWidget {
  const CanteenSupplyScreen({super.key});

  @override
  State<CanteenSupplyScreen> createState() => _CanteenSupplyScreenState();
}

class _CanteenSupplyScreenState extends State<CanteenSupplyScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Hamısı';

  final List<CanteenSupplyItem> _supplies = [
    CanteenSupplyItem(
      id: 'cant-1',
      name: 'Pasterizə Süd (1.5% Milla 1L)',
      category: 'Süd məhsulları',
      quantity: 80.0,
      unit: 'litr',
      receivedDate: DateTime(2026, 10, 30),
      expiryDate: DateTime(2026, 11, 04),
      supplier: 'AZ FP CO LTD (Milla)',
      cost: 160.0,
    ),
    CanteenSupplyItem(
      id: 'cant-2',
      name: 'Təzə Kərə Yağı (82.5% Qaymaq)',
      category: 'Süd məhsulları',
      quantity: 25.0,
      unit: 'kq',
      receivedDate: DateTime(2026, 10, 28),
      expiryDate: DateTime(2026, 11, 28),
      supplier: 'Azərsun Holdinq',
      cost: 450.0,
    ),
    CanteenSupplyItem(
      id: 'cant-3',
      name: 'Mövsümi Alma və Banan',
      category: 'Tərəvəz və Meyvə',
      quantity: 110.0,
      unit: 'kq',
      receivedDate: DateTime(2026, 11, 01),
      expiryDate: DateTime(2026, 11, 07),
      supplier: 'Meyvəli Aqro MMC',
      cost: 245.0,
    ),
    CanteenSupplyItem(
      id: 'cant-4',
      name: 'Kəpəkli və Ağ Baton Çörək',
      category: 'Çörək',
      quantity: 150.0,
      unit: 'ədəd',
      receivedDate: DateTime(2026, 11, 02),
      expiryDate: DateTime(2026, 11, 03),
      supplier: '№1 Çörək Zavodu',
      cost: 97.50,
    ),
    CanteenSupplyItem(
      id: 'cant-5',
      name: 'Mal Əti (Sümüksüz Qulyajlıq)',
      category: 'Ərzaq',
      quantity: 40.0,
      unit: 'kq',
      receivedDate: DateTime(2026, 10, 31),
      expiryDate: DateTime(2026, 11, 03),
      supplier: 'Halal Qida Tədarük',
      cost: 680.0,
    ),
  ];

  final List<String> _categories = [
    'Hamısı',
    'Ərzaq',
    'Süd məhsulları',
    'Tərəvəz və Meyvə',
    'Çörək',
  ];

  List<CanteenSupplyItem> get _filteredSupplies {
    final query = _searchController.text.trim().toLowerCase();
    return _supplies.where((sup) {
      final matchesCategory = _selectedCategory == 'Hamısı' || sup.category == _selectedCategory;
      final matchesSearch = query.isEmpty ||
          sup.name.toLowerCase().contains(query) ||
          sup.supplier.toLowerCase().contains(query);
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
    final expiringCount = _supplies.where((s) => s.isExpiringSoon || s.isExpired).length;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Yeməkxana və Təchizat', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 0,),
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
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Gündəlik Qida Təminatı',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$expiringCount ərzağın son istifadə müddəti yaxınlaşır',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
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
              hintText: 'Ərzaq və ya təchizatçı adı ilə axtarış...',
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
              title: 'Mövcud Ərzaq Ehtiyatları',
              trailing: '${_filteredSupplies.length} növ',
            ),
            const SizedBox(height: 8),
            if (_filteredSupplies.isEmpty)
              ModernCard(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(Icons.kitchen, size: 48, color: AppColors.getTextSecondary(context)),
                      const SizedBox(height: 12),
                      Text(
                        'Axtarışa uyğun ərzaq tapılmadı',
                        style: TextStyle(color: AppColors.getTextSecondary(context)),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._filteredSupplies.map((sup) {
                final isWarning = sup.isExpiringSoon || sup.isExpired;

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
                                  color: (isWarning ? AppColors.warning : AppPalette.primary)
                                      .withValues(alpha: 0.1),
                                  borderRadius: AppRadius.smRadius,
                                ),
                                child: Icon(
                                  Icons.fastfood_rounded,
                                  color: isWarning ? AppColors.warning : AppPalette.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sup.name,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.getTextPrimary(context),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${sup.category} • ${sup.supplier}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.getTextSecondary(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              StatusBadge(
                                label: isWarning ? 'Müddət bitir' : 'Təzə',
                                color: isWarning ? AppColors.warning : AppColors.success,
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
                                    'Qalıq Həcmi',
                                    style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(context)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${sup.quantity} ${sup.unit}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.getTextPrimary(context),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Qəbul Tarixi',
                                    style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(context)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${sup.receivedDate.day.toString().padLeft(2, '0')}.${sup.receivedDate.month.toString().padLeft(2, '0')}.${sup.receivedDate.year}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.getTextSecondary(context),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Son Tarix',
                                    style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(context)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${sup.expiryDate.day.toString().padLeft(2, '0')}.${sup.expiryDate.month.toString().padLeft(2, '0')}.${sup.expiryDate.year}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: isWarning ? AppColors.error : AppPalette.primary,
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
                );
              }),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
