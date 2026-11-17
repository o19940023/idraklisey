# TAPŞIRIQ: [SINIFLER] MODULUNUN WEB-DƏN MOBİLƏ (FLUTTER) 100% PARİTETLƏ KÖÇÜRÜLMƏSİ

## 1. Layihə Konteksti və Qovluq Konumları
Bu sistem fəaliyyətdə olan "İdrak Liseyi İdarəetmə Sistemi"dir. Sistem iki əsas hissədən ibarətdir:
1. **Web GoPanel (Laravel Backend):** `D:\IdrakSchoolManagment\Idrak_Backend_Panel\source`
   - **Veb Kontrollerləri:** `app/Http/Controllers/` (Academic, Exam, Medical, Psychology, HR və s.)
   - **Veb Blade Ekranları və JS:** `resources/views/gopanel/` və `public/gopanel/`
   - **Modellər & Əlaqələr:** `app/Models/`
   - **Mobil API Kontrolleri:** `app/Http/Controllers/Api/Mobile/MobileApiController.php`
   - **API Marşrutları:** `routes/api.php`
2. **Mobil Tətbiq (Flutter):** `D:\IdrakLiseyiGUNCEL`
   - **Modul Ekranları:** `lib/modules/`
   - **API Servisi:** `lib/core/services/school_api_service.dart`
   - **Sessiya & Rollar:** `lib/core/session/session_controller.dart`, `lib/providers/app_state.dart`

---

## 2. DƏYİŞMƏZ ƏSAS QAYDALAR (ÇOX VACİB)
1. **Web Sistemə və Bazaya ƏSLA Toxunulmayacaq:**
   - Mövcud web kontrollerləri, blade faylları, miqrasiyalar və ya baza cədvəllərinin strukturu qətiyyən dəyişdirilə bilməz!
   - Real serverdəki heç bir canlı məlumat pozulmamalıdır.
   - Bütün yeni mobil API məntiqləri yalnız `MobileApiController.php` daxilində və ya təhlükəsiz şəkildə `routes/api.php` vasitəsilə əlavə edilməlidir.
2. **Heç bir Məlumatı və ya ID-ni Hardcode Etməyin:**
   - Heç bir rol, sinif, şagird və ya valideyn üçün statik sınaq ID-si yazmayın. Real serverə yükləndikdə hər şey dinamik və qüsursuz işləməlidir.

---

## 3. ARAŞDIRMA VƏ ANALİZ MƏRHƏLƏSİ (Addım-addım)
Modul üzərində işə başlamazdan əvvəl aşağıdakıları araşdır və mənə qısa plan təqdim et:
1. **Vebdə Bu Modul Necə İşləyir?**
   - Vebdəki aidiyyəti Blade şablonunu (`resources/views/gopanel/...`) və əlaqəli JS skriptlərini oxu.
   - Cədvəldə hansı sütunlar var? Hansı filtrlər (tablar, açılan siyahılar, axtarış) mövcuddur?
   - Modulda hansı sayğaclar (badge/counts) hesablanır?
   - Hansı modal pəncərələr, əməliyyat düymələri (əlavə et, redaktə et, sil, status dəyiş, təsdiqlə/imtina et) var?
2. **Rol və İcazə Matrisi (RBAC / Spatie):**
   - Vebdə `@can('...')` və ya `user->hasRole(...)` ilə hansı elementlərin gizlədildiyini yoxla.
   - Fərqli rollar (məsələn: SuperAdmin, Akademik/Direktor, İmtahan rəhbəri, Psixoloq, Həkim, Müəllim, Valideyn) daxil olduqda nəyi görür və nəyi görməməlidir?
   - Mobil tətbiqdə istifadəçinin icazəsi olmayan menyu, tab, düymə və ya giriş məlumatları (login/şifrə kimi) qətiyyən görünməməlidir!
3. **Gizli və Detal Əlaqələr:**
   - Soft-delete (`deleted_at is null`), aktivlik (`is_active`), birləşdirilmiş qeydlər (`[Birləşdirildi...]`) kimi istisnaları nəzərə al.
   - Əlaqəli cədvəllərdəki (məsələn siniflər, fənlər, şagirdlər) dublikat açarların Flutter Dropdown-da xəta (`There should be exactly one item with value`) verməməsi üçün unikal id filtrasiyası apar.

---

## 4. TƏTBİQ VƏ DİZAYN TƏLƏBLƏRİ (Flutter UI/UX)
1. **Professional və Təmiz UI:**
   - Yan tərəflərdə lazımsız böyük boşluqlar qalmamalıdır (`horizontal padding: 12-16`).
   - Mətnlərin kəsilməməsi üçün ad və başlıqlarda `maxLines: 2` istifadə edilməlidir.
   - Siyahının ən aşağısında yerləşən Floating Action Button (və ya alt çubuğun) kartlardakı düymələri örtməməsi üçün siyahının altına ən az `bottom: 120-140` daxili məsafə (padding) verilməlidir.
   - Rənglər və status nişanları (məsələn: Gözləmədə = sarı, Təsdiq = yaşıl, İmtina = qırmızı) vebdəki GoPanel rəng palitrası ilə 1:1 uyğun olmalıdır.
2. **API & Şəbəkə İnteqrasiyası:**
   - `school_api_service.dart` daxilində təmiz, tipləşdirilmiş metodlar yazılmalıdır.
   - Xəta baş verdikdə (`500`, `403`, internet kəsilməsi) ekran qırılmamalı, istifadəçiyə anlaşıqlı bildiriş və "Yenidən yoxla" düyməsi göstərilməlidir.

---

## 5. TEST VƏ TƏSDİQ PROTOKOLU
Hər bir dəyişiklikdən sonra:
1. `php -l app/Http/Controllers/Api/Mobile/MobileApiController.php` əmri ilə sintaksis xətalarının olmadığını təsdiq et.
2. `flutter run` / hot reload ilə tətbiqi emulyatorda yoxla.
3. Ekran görüntüsünü (screenshot) və UI ağacını çəkib yoxlayaraq dizaynın və məlumatların ekranda düzgün oturduğunu təsdiqlədikdən sonra mənə hesabat ver.