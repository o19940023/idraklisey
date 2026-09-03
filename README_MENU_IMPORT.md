# Lisey Yemekxana Menyusu - Import Təlimatı

## 📋 Ümumi Məlumat

Bu layihədə Lisey yemekxana menyusu Firebase Firestore-ə avtomatik yüklənir. Menyu həm səhər həm də günorta yeməklərini əhatə edir.

## 🍽️ Menyu Strukturu

Hər gün üçün 2 ayrı menyu var:
- **Səhər (08:00 - 08:30)**: Səhər yeməkləri
- **Günorta (12:30 - 13:30)**: Günorta yeməkləri

### Daxil Edilmiş Günlər:
1. **Çərşənbə axşamı (02.09.2026)**
   - Səhər: Xama, əncir cemi, kərə yağı, buğda çörəyi, şirin çay, omlet
   - Günorta: Plov, toyuq kababı, çoban salatı, zoğal xoşabı, buğda çörəyi, dovğa

2. **Çərşənbə (03.09.2026)**
   - Səhər: Şor, alma cemi, kərə yağı, buğda çörəyi, şirin çay, düyü sıyığı
   - Günorta: Qarabaşaq, qulyaj, xiyar, reyhan şərbəti, buğda çörəyi, qırmızı mərci şorbası

3. **Cümə axşamı (04.09.2026)**
   - Səhər: Brınza pendiri, ərik cemi, kərə yağı, buğda çörəyi, şirin çay, vafli
   - Günorta: Dana ətindən kotlet, kartof, pomidor qızartması, manqal salatı, alça xoşabı, doğramac

4. **Cümə (05.09.2026)**
   - Səhər: Şor, çiyələk cemi, kərə yağı, buğda çörəyi, şirin çay, yulaf sıyığı
   - Günorta: İtalyan sayağı spagetti, toyuq salatı, göyəm xoşabı, buğda çörəyi, düyü şorbası

## 🚀 Menyunu Yükləmək

### Admin Panelindən (Tövsiyə Edilən)

1. **Admin kimi daxil olun** (`admin` / `123`)
2. **Yemekxana Menyusu** bölməsinə gedin
3. Yuxarıda **📤 Upload** düyməsini basın
4. Təsdiq edin

Menyu avtomatik Firebase'e yükləniləcək və bütün istifadəçilər göra biləcək.

### Fayllar

- **`lib/admin/import_menu_helper.dart`**: Menyu məlumatlarını ehtiva edir
- **`scripts/menu_data.json`**: JSON formatında menyu (Firebase Console üçün)
- **`scripts/add_cafeteria_menu.dart`**: Dart skripti (manual import üçün)

## 📊 Kalori Məlumatları

Hər yemək üçün kalori miqdarları təqribi olaraq hesablanmışdır:
- Omlet: 200 kkal
- Plov: 450 kkal
- Toyuq kababı: 280 kkal
- Şorba: 140-160 kkal
- Salat: 30-110 kkal
- Çay: 50 kkal
- Və s.

## 🏷️ Allergenlər

Sistem aşağıdakı allergenləri qeyd edir:
- **Qlüten**: Buğda çörəyi, makaron, vafli
- **Süd**: Kərə yağı, pendiri, dovğa
- **Yumurta**: Omlet, vafli

## 🔄 Menyunu Yeniləmək

Menyunu dəyişmək üçün:

### 1. Kod ilə
`lib/admin/import_menu_helper.dart` faylında `_getLiseyMenuData()` metodunu dəyişdirin.

### 2. Admin panelindən
Admin kimi daxil olub hər bir yeməyi ayrı-ayrılıqda əlavə edə və ya silə bilərsiniz.

## 📱 İstifadəçi Görünüşü

Şagird, valideyn və müəllim panelində menyunu görə bilərlər:
- Günlərə görə switch
- Hər yemək üçün: şəkil, ad, kalori, çəki, allergenlər
- Gün üzrə cəmi kalori

Admin və səlahiyyətli müəllimlər menyu idarə edə bilərlər.

## ✅ Uğurlu Import Əlamətləri

- Firebase Console-da `cafeteria_menu` kolleksiyasında 8 document (4 gün × 2 öğün)
- Hər document-də `dayName`, `date`, `mealTime`, `totalCalories`, `items` sahələri
- Tətbiqdə menyunun görünməsi

## ⚠️ Qeydlər

- Tarixlər 2026-09-02 - 2026-09-05 arasındadır
- Sistem həftənin günlərinə görə avtomatik seçim etmir
- Admin manual olaraq yeni günlər əlavə edə bilər
- Şəkillər Unsplash-dan götürülmüşdür (placeholder)

## 🆘 Problemlər

Əgər menyu görünmürsə:
1. Firebase connection yoxlayın
2. Admin olaraq düyməyə bir daha basın
3. Firebase Console-dan manual yoxlayın
4. Tətbiqi yenidən başladın

---

**Son Yeniləmə:** 03.09.2026  
**Hazırlayan:** Kiro AI Assistant
