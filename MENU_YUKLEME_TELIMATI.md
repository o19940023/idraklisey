# 🍽️ Yemekxana Menyusunu Yükləmək Üçün Təlimat

## ✅ Addımlar:

### 1. Tətbiqi Aç və Admin Kimi Daxil Ol
```
İstifadəçi adı: admin
Şifrə: 123
```

### 2. Yemekxana Menyusu Bölməsinə Get
- Alt menyudan "Yemekxana Menyusu" seçin

### 3. Upload Düyməsinə Bas
- Yuxarıda qızılı rəngdə 📤 (upload file) düyməsi görəcəksən
- Tooltip: "Lisey Menyusunu Yüklə (TEK DƏFƏ)"
- Bu düyməyə bas

### 4. Təsdiq Et
- Dialog pəncərəsi açılacaq
- "Yüklə" düyməsinə bas
- Bir neçə saniyə gözlə

### 5. Uğur Mesajını Gör
- "✅ Lisey menyusu uğurla yükləndi!" mesajı görünəcək
- İndi 4 gün menyu görünməlidir:
  - Çərşənbə axşamı
  - Çərşənbə
  - Cümə axşamı
  - Cümə

### 6. Yoxla
- Hər gündə:
  - 🌅 SƏHƏR YEMƏKLƏRİ (başlıq)
  - Səhər yeməkləri (6-7 item)
  - ☀️ GÜNORTA YEMƏKLƏRİ (başlıq)
  - Günorta yeməkləri (7-8 item)

## 🗑️ Düyməni Silmək (Yükləmədən SONRA)

Menyu yükləndi? İndi upload düyməsini siləcəyik:

### Addım 1: Faylı Aç
`lib/modules/student/screens/cafeteria_menu_screen.dart`

### Addım 2: Bu hissəni tap (təxminən 75-85 sətir)
```dart
// ⚠️ BU DÜYMƏ BİR DƏFƏ İŞLƏDİLDİKDƏN SONRA SİLİNƏCƏK
if (currentUser?.role == UserRole.admin)
  IconButton(
    icon: const Icon(
      Icons.upload_file,
      color: AppColors.goldDark,
      size: 18,
    ),
    tooltip: 'Lisey Menyusunu Yüklə (TEK DƏFƏ)',
    onPressed: () => _importLiseyMenu(context, appState),
  ),
```

### Addım 3: SİL!
Yuxarıdakı 11 sətri tamamilə sil (şərhdən başlayaraq `),` daxil)

### Addım 4: Funksiyanı da sil (opsional)

Faylın sonunda (təxminən 683-750 sətir arası) bu funksiyanı tap və sil:

```dart
// Lisey menyusunu Firebase'e yüklə
void _importLiseyMenu(BuildContext context, AppState appState) {
  ...
  // Bütün funksiyanı sil
}
```

### Addım 5: Yadda saxla və yenidən başlat
- Faylı yadda saxla (Ctrl+S)
- Tətbiqi yenidən işə sal
- Artıq upload düyməsi görünməyəcək ✅

## 📱 Nəticə

İndi:
- ✅ 4 gün menyu var
- ✅ Hər gündə səhər və günorta birlikdə
- ✅ Başlıqlar aydın görünür
- ✅ Upload düyməsi yoxdur
- ✅ Admin manual yemək əlavə edə bilər
- ✅ Tələbələr menyunu görə bilərlər

## 🎉 Tamamdır!

Artıq menyunu Firebase-də saxlayırsan və istədiyən zaman manual dəyişə bilərsən!

---
**Qeyd:** Upload düyməsini silmək məcburi deyil, amma bir dəfə işlətdikdən sonra ehtiyac yoxdur.
