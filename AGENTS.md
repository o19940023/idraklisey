# İdrak Liseyi - Flutter 2026 Mobil Mimari ve Çalışma Standartları

Bu proje, hem **iOS** hem de **Android** platformlarını hedefleyen modern, kurumsal bir Flutter mobil uygulamasıdır (`idrak_liseyi`).
Tüm ajanlar (DeepSeek, GLM-5.3, MiniMax M3.1, MiMo V2.6) aşağıdaki 2026 mobil yazılım ve tasarım standartlarına harfiyen uyarak çalışmalıdır:

---

## 1. 2026 Modern Mobil Tasarım ve UI/UX Standartları
- **Platform Adaptifliği (Cross-Platform):**
  - Android için modern **Material 3 (Material You)**, iOS için **Cupertino** tasarım diline uyum sağla.
  - Dialog, switch ve ikonlarda platform adaptif widget'ları tercih et (`Switch.adaptive`, `Icons.adaptive`, `showAdaptiveDialog`).
  - Safe Area, Dynamic Island ve katlanabilir (foldable) ekran geometrilerini her zaman hesaba kat.
- **Akıcılık & Mikro-Etkileşimler:**
  - Projede bulunan `flutter_animate` paketini aktif kullan. Ekran açılışlarında, buton tıklamalarında ve liste kaydırmalarında 120Hz akıcı, zarif mikro-animasyonlar ekle.
  - Şık kart tasarımları, yumuşak gölgeler, `google_fonts` tipografi hiyerarşisi ve modern kenar yuvarlaklıkları (`BorderRadius.circular(16)`) uygula.
- **Responsive & Erişilebilirlik:**
  - Ekran boyutuna göre esneyebilen `LayoutBuilder` veya `MediaQuery` yapıları kullan, asla ekran taşması (`RenderFlex overflowed`) hatası bırakma.

---

## 2. Kodlama & Performans Standartları (Flutter & Dart 3.x)
- **State Management:** Projedeki `Provider` mimarisini temiz şekilde uygula. UI widget'larını gereksiz yeniden çizdirmekten kaçın (`Consumer` veya `Selector` kullan).
- **Dart 3.x Özellikleri:** Pattern matching (`switch expression`), modern records ve güçlü tip güvenliğini kullan.
- **Performans & Bellek:**
  - Mümkün olan her yerde `const` constructor kullan (`const SizedBox()`, `const Text()`).
  - `TextEditingController`, `AnimationController`, `StreamSubscription` gibi tüm kaynakları ilgili `StatefulWidget`'ın `dispose()` metodunda mutlaka serbest bırak.
- **Firebase & Veritabanı:**
  - Firestore veri modellerini `fromJson` ve `toJson` metodlarıyla tip güvenli (type-safe) sınıflar olarak yaz.
  - Ağ trafiğini ve kota kullanımını optimize et.

---

## 3. Android Studio, Emülatör & Test Entegrasyonu
- Ajanlar projede terminal üzerinden tam yetkilidir (`permission: allow`).
- Kod düzenlemesi bittiğinde gerekirse arka planda şu komutları çalıştırarak projeyi doğrulayabilirler:
  - `flutter analyze` : Sözdizimi veya tip hatalarını kontrol eder.
  - `flutter pub get` : Yeni paket bağımlılıklarını çözer.
  - `flutter test` : Testleri koşturur.
  - `adb devices` ve `flutter run -d emulator-5554` : Canlı Android emülatör üzerinde çalıştırma ve log inceleme.

---

## 4. Ajan Rolleri
1. **Lider & Baş Mimar (DeepSeek V4.1):** Gereksinimi analiz eder, mimari kararları alır, alt ajanlara görevleri dağıtır.
2. **Kıdemli Flutter Geliştirici (@coder - GLM-5.3):** Widget ağacını, servisleri, ekranları ve Provider modellerini eksiksiz yazar.
3. **UI/UX & Sistem Mimarı (@architect - MiniMax M3.1):** 2026 tasarım çizgilerini, tema uyumunu (Dark/Light) ve responsive mimariyi denetler.
4. **Kalite & QA Denetçisi (@reviewer - MiMo V2.6):** `flutter analyze` çıktısını inceler, bellek sızıntılarını önler ve yapılan geliştirmeleri Türkçe özetler.
