import 'package:flutter/foundation.dart';

import '../data/models/menu_model.dart';
import '../services/firestore_service.dart';

/// Lisey yeməkxana menyusunu Firebase-ə yükləyir.
///
/// Hər həftənin menyusu ayrıca saxlanılır (sənəd ID-si tarixə əsaslanır) —
/// yeni həftə yüklədikcə əvvəlki həftələr silinmir.
class MenuImportHelper {
  MenuImportHelper._();

  static final FirestoreService _firestoreService = FirestoreService();

  /// Bütün mövcud həftələrin menyusunu Firebase-ə yükləyir.
  /// Eyni tarixli günlər yenilənir, digər həftələrə toxunulmur.
  static Future<void> importLiseyMenu() async {
    final menus = [..._getCurrentWeekMenu(), ..._getNextWeekMenu()];
    await _firestoreService.importMenus(menus);
    debugPrint('✅ ${menus.length} günlük menyu Firebase-ə yükləndi');
  }

  // --- Kompakt yemək qurucuları ---

  static const _mainImg =
      'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=400';
  static const _soupImg =
      'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400';
  static const _saladImg =
      'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=400';
  static const _sideImg =
      'https://images.unsplash.com/photo-1589985270826-4b7bb135bc9d?w=400';
  static const _drinkImg =
      'https://images.unsplash.com/photo-1564890369478-c89ca6d9cde9?w=400';

  static String _imgFor(String category) {
    switch (category) {
      case 'Şorba':
        return _soupImg;
      case 'Salat':
        return _saladImg;
      case 'Qarnir':
        return _sideImg;
      case 'Şirniyyat / İçki':
        return _drinkImg;
      default:
        return _mainImg;
    }
  }

  static MenuItem _m(
    String name,
    String category,
    int calories,
    String weightGram, [
    List<String> allergens = const [],
  ]) {
    return MenuItem(
      name: name,
      category: category,
      calories: calories,
      weightGram: weightGram,
      allergens: allergens,
      imageUrl: _imgFor(category),
    );
  }

  // Tez-tez təkrarlanan standart məhsullar
  static MenuItem _kereYagi() =>
      _m('Kərə Yağı', 'Qarnir', 100, '20g', ['Süd']);
  static MenuItem _corek() =>
      _m('Buğda Çörəyi', 'Əsas Yemək', 180, '80g', ['Qlüten']);
  static MenuItem _sirinCay() => _m('Şirin Çay', 'Şirniyyat / İçki', 50, '200ml');
  static MenuItem _sufreSuyu() =>
      _m('Süfrə Suyu', 'Şirniyyat / İçki', 0, '200ml');

  static MenuItem _basiq(String title) => MenuItem(
        name: title,
        category: 'Başlıq',
        calories: 0,
        weightGram: '',
        allergens: [],
        imageUrl: '',
      );

  /// Bir günlük menyu: səhər + günorta yeməkləri başlıqlarla birlikdə
  static DailyMenu _day(
    String dayName,
    DateTime date,
    List<MenuItem> breakfast,
    List<MenuItem> lunch,
  ) {
    final items = [
      _basiq('🌅 SƏHƏR YEMƏKLƏRİ'),
      ...breakfast,
      _basiq('☀️ GÜNORTA YEMƏKLƏRİ'),
      ...lunch,
    ];
    return DailyMenu(
      dayName: dayName,
      date: date,
      mealTime: 'Səhər və Günorta',
      items: items,
      totalCalories: items.fold(0, (sum, i) => sum + i.calories),
    );
  }

  // --- 1-ci həftə: 02–05.09.2026 ---

  static List<DailyMenu> _getCurrentWeekMenu() {
    return [
      _day('Çərşənbə axşamı', DateTime(2026, 9, 2), [
        _m('Xama', 'Əsas Yemək', 250, '150g'),
        _m('Əncir Cemi', 'Şirniyyat / İçki', 120, '50g'),
        _kereYagi(),
        _corek(),
        _sirinCay(),
        _m('Omlet', 'Əsas Yemək', 200, '120g', ['Yumurta']),
      ], [
        _m('Plov', 'Əsas Yemək', 450, '250g'),
        _m('Toyuq Kababı', 'Əsas Yemək', 280, '150g'),
        _m('Çoban Salatı', 'Salat', 80, '120g'),
        _m('Zoğal Xoşabı', 'Şirniyyat / İçki', 90, '200ml'),
        _corek(),
        _sufreSuyu(),
        _m('Dovğa', 'Şorba', 150, '250ml', ['Süd']),
      ]),
      _day('Çərşənbə', DateTime(2026, 9, 3), [
        _m('Şor', 'Əsas Yemək', 230, '150g'),
        _m('Alma Cemi', 'Şirniyyat / İçki', 110, '50g'),
        _kereYagi(),
        _corek(),
        _sirinCay(),
        _m('Düyü Sıyığı', 'Əsas Yemək', 220, '200g'),
      ], [
        _m('Qarabaşaq', 'Əsas Yemək', 380, '250g', ['Qlüten']),
        _m('Qulyaj', 'Əsas Yemək', 320, '180g'),
        _m('Xiyar', 'Salat', 30, '100g'),
        _m('Reyhan Şərbəti', 'Şirniyyat / İçki', 70, '200ml'),
        _corek(),
        _sufreSuyu(),
        _m('Qırmızı Mərci Şorbası', 'Şorba', 160, '250ml'),
      ]),
      _day('Cümə axşamı', DateTime(2026, 9, 4), [
        _m('Brınza Pendiri', 'Əsas Yemək', 200, '100g', ['Süd']),
        _m('Ərik Cemi', 'Şirniyyat / İçki', 130, '50g'),
        _kereYagi(),
        _corek(),
        _sirinCay(),
        _m('Vafli', 'Şirniyyat / İçki', 240, '80g', ['Qlüten', 'Yumurta']),
      ], [
        _m('Dana Ətindən Kotlet', 'Əsas Yemək', 350, '150g'),
        _m('Kartof', 'Qarnir', 200, '180g'),
        _m('Pomidor Qızartması', 'Salat', 90, '100g'),
        _m('Manqal Salatı', 'Salat', 110, '120g'),
        _m('Alça Xoşabı', 'Şirniyyat / İçki', 85, '200ml'),
        _corek(),
        _sufreSuyu(),
        _m('Doğramac', 'Şorba', 140, '250ml'),
      ]),
      _day('Cümə', DateTime(2026, 9, 5), [
        _m('Şor', 'Əsas Yemək', 230, '150g'),
        _m('Çiyələk Cemi', 'Şirniyyat / İçki', 140, '50g'),
        _kereYagi(),
        _corek(),
        _sirinCay(),
        _m('Yulaf Sıyığı', 'Əsas Yemək', 210, '200g'),
      ], [
        _m('İtalyan Sayağı Spagetti', 'Əsas Yemək', 420, '250g', ['Qlüten']),
        _m('Toyuq Salatı', 'Salat', 190, '150g'),
        _m('Göyəm Xoşabı', 'Şirniyyat / İçki', 80, '200ml'),
        _corek(),
        _sufreSuyu(),
        _m('Düyü Şorbası', 'Şorba', 150, '250ml'),
      ]),
    ];
  }

  // --- 2-ci həftə: 07–11.09.2026 ---

  static List<DailyMenu> _getNextWeekMenu() {
    return [
      // Bazar ertəsi - 07.09.2026
      _day('Bazar ertəsi', DateTime(2026, 9, 7), [
        _m('Brınza Pendiri', 'Əsas Yemək', 200, '100g', ['Süd']),
        _m('Çiyələk Cemi', 'Şirniyyat / İçki', 140, '50g'),
        _kereYagi(),
        _corek(),
        _sirinCay(),
        _m('Mannı Sıyığı', 'Əsas Yemək', 210, '200g', ['Süd']),
      ], [
        _m('Qovrulmuş Vermeşil', 'Əsas Yemək', 380, '250g'),
        _m('Dana Ətindən Balanes', 'Əsas Yemək', 330, '150g'),
        _m('Xiyar', 'Salat', 30, '100g'),
        _m('Zoğal Xoşabı', 'Şirniyyat / İçki', 90, '200ml'),
        _corek(),
        _sufreSuyu(),
        _m('Lobya Şorbası', 'Şorba', 170, '250ml'),
      ]),
      // Çərşənbə axşamı - 08.09.2026
      _day('Çərşənbə axşamı', DateTime(2026, 9, 8), [
        _m('Şor', 'Əsas Yemək', 230, '150g'),
        _m('Şaftalı Cemi', 'Şirniyyat / İçki', 120, '50g'),
        _kereYagi(),
        _corek(),
        _sirinCay(),
        _m('Şokoladlı Peçenye', 'Şirniyyat / İçki', 180, '60g', ['Qlüten']),
      ], [
        _m('Bulqur', 'Əsas Yemək', 350, '250g', ['Qlüten']),
        _m('Butoçki', 'Əsas Yemək', 320, '220g', ['Qlüten']),
        _m('Əzmə Pomidor', 'Salat', 60, '100g'),
        _m('Göyəm Xoşabı', 'Şirniyyat / İçki', 80, '200ml'),
        _corek(),
        _sufreSuyu(),
        _m('Tərəvəz Şorbası', 'Şorba', 150, '250ml'),
      ]),
      // Çərşənbə - 09.09.2026
      _day('Çərşənbə', DateTime(2026, 9, 9), [
        _m('Xama', 'Əsas Yemək', 250, '150g'),
        _m('Əncir Cemi', 'Şirniyyat / İçki', 120, '50g'),
        _kereYagi(),
        _corek(),
        _sirinCay(),
        _m('Soyutma Yumurta', 'Əsas Yemək', 150, '100g', ['Yumurta']),
      ], [
        _m('Badımcan, Pomidor, Kartof Qızartması', 'Əsas Yemək', 300, '220g'),
        _m('Kahı Salatı', 'Salat', 40, '100g'),
        _m('Şaftalı Xoşabı', 'Şirniyyat / İçki', 85, '200ml'),
        _corek(),
        _sufreSuyu(),
        _m('Doğramac', 'Şorba', 140, '250ml'),
      ]),
      // Cümə axşamı - 10.09.2026
      _day('Cümə axşamı', DateTime(2026, 9, 10), [
        _m('Şor', 'Əsas Yemək', 230, '150g'),
        _m('Ərik Cemi', 'Şirniyyat / İçki', 130, '50g'),
        _kereYagi(),
        _corek(),
        _sirinCay(),
        _m('Vermeşil Sıyığı', 'Əsas Yemək', 220, '200g', ['Süd']),
      ], [
        _m('Plov', 'Əsas Yemək', 450, '250g'),
        _m('Toyuq Çığırtması', 'Əsas Yemək', 300, '150g'),
        _m('Çoban Salatı', 'Salat', 80, '120g'),
        _m('Limon Şərbəti', 'Şirniyyat / İçki', 70, '200ml'),
        _corek(),
        _sufreSuyu(),
        _m('Dovğa', 'Şorba', 150, '250ml', ['Süd']),
      ]),
      // Cümə - 11.09.2026
      _day('Cümə', DateTime(2026, 9, 11), [
        _m('Brınza Pendiri', 'Əsas Yemək', 200, '100g', ['Süd']),
        _m('Alma Cemi', 'Şirniyyat / İçki', 110, '50g'),
        _kereYagi(),
        _corek(),
        _sirinCay(),
        _m('Cemli Piroq', 'Şirniyyat / İçki', 260, '90g', ['Qlüten', 'Yumurta']),
      ], [
        _m('Püre', 'Qarnir', 200, '180g', ['Süd']),
        _m('Şnitsel', 'Əsas Yemək', 360, '150g'),
        _m('Leço', 'Qarnir', 120, '150g'),
        _m('Reyhan Şərbəti', 'Şirniyyat / İçki', 70, '200ml'),
        _corek(),
        _sufreSuyu(),
        _m('Makaron Şorbası', 'Şorba', 160, '250ml', ['Qlüten']),
      ]),
    ];
  }
}
