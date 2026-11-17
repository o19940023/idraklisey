# Laravel Web Sistemi — Faz 0 Keşif Raporu (Canlı Sondaj, SALT-OKUNUR)

> Tarih: 2026-10-23 · Yöntem: normal browser benzeri GET istekleri + login oturumu.
> Sunucuda hiçbir veri değiştirilmedi (sadece GET; tek POST = normal login).

## 1) Kimlik / Auth Mekanizması
- URL: `https://portal.idrak.edu.az`
- Sistem: Laravel (session tabanlı) — cookie: `idrak_liseyi_session` + `XSRF-TOKEN`
- Login formu: `/panel/auth/login` (POST)
  - Alanlar: `_token` (CSRF), `login_type` (`fin` | `email`), `login_value`, `password`
  - Response: 200 (redirect takibiyle dashboard)
- *(Not: token/şifre burada DEPOLANMAZ)*

## 2) 60+ Endpoint canlı sonucu (IT rolü ile)
- `/panel/profile` → HTTP 200, tam sayfa (77 KB) ✅ çalışıyor
- `/panel/notifications/get-latest` → HTTP 401 (rota var, auth/izin şartı farklı — muhtemelen JSON API noktası) ⚠️
- Diğer TÜM panel rotaları → HTTP 200 + ~15.9 KB **standart "erişim-yok/boş" şablonu**
  → Yani rotalar mevcut, ama rol granular engelliyor (404 vermiyor → rotalar canlı)
- `/panel/academic/students` ayrı fetch'te tam sayfa (167 KB) döndü, `dataTables` altyapısı var ama `<tbody>` boş → veri AJAX ile yükleniyor

## 3) IT Rolünün Görüntülediği Menü (dashboard'dan çıkarıldı)
- `Əsas səhifə` (`/panel`) — özel IT dashboard'u + "Açıq biletlər" widget'ı (30 saniyede bir yenilenen)
- `Həftəlik menyu` → **`/panel/parent/weekly-menu`** (api_config'te OLMAYAN yeni keşif!)
- `Dəstək biletləri` (`/panel/tickets`) — başlık "Biletlər", AJAX tablo (o kullanıcı için satır görünmedi/boş olabilir)
- `E-məktəb` alt menüsü sidebar'da render ediliyor ama sayfa içerikleri rol için engel/boş
- `E-posta` login tipi de mevcut (`login_type=email`)

## 4) Mimarî GERÇEK: Panel = Server-Rendered Blade + DataTables (JSON API DEĞİL)
- Sayfalar Blade HTML; listeler DataTables AJAX ile post-login gelir
- **Sonuç:** Mobil entagrasiya için bu rotaları HTML-parça olarak tüketmek DOĞRU DEĞİL
- Doğru yol: Laravel'e **additive API katmanı** ekleme (zip'ten Sonra):
  - `routes/api.php` + Sanctum, modellerin üstünde JSON controller'lar (mevcut modeller referans alınarak)
  - Panel mantığına dokunulmaz; web ayrı, mobil API ayrı tüketir

## 5) App'e Eklenen Kod (bu keşif sonucunda)
- `lib/services/network/api_config.dart`:
  - `WEEKLY_MENU = '/panel/parent/weekly-menu'` eklendi (Haftalık menyu endpoint'i)

## 6) Sonraki Adım
- Zip kaynak kodu → gerçek envanter (modül/rol/ekran/DB şeması) raporu
- İzin matrisi + class-merge + alumni algoritmalarının koddan okunması
- API katmanı tasarımı (Sanctum + JSON Resource'lar)
