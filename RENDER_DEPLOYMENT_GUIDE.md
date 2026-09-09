# 🚀 Render.com Deployment Guide - Agora Token Server

## ✅ Yapılanlar

1. ✅ **Backend server oluşturuldu** - `agora-token-server/` klasörü
2. ✅ **Flutter client güncellendi** - Artık backend'den token alıyor
3. ✅ **Güvenlik sorunu çözüldü** - App Certificate artık client-side'da YOK!

## 📋 Render.com'a Deploy Adımları

### 1️⃣ GitHub'a Push Et

```bash
cd d:\IdrakLiseyiGUNCEL
git add agora-token-server/
git add lib/services/agora_token_service.dart
git add lib/services/agora_service.dart
git commit -m "feat: Agora token server added (Render.com)"
git push
```

### 2️⃣ Render.com Hesabı Oluştur

1. [render.com](https://render.com) aç
2. "Get Started for Free" tıkla
3. GitHub ile giriş yap

### 3️⃣ Web Service Oluştur

1. Dashboard'da **"New +"** → **"Web Service"** tıkla
2. GitHub repository'ni bağla
3. Repository seç: `IdrakLiseyiGUNCEL` (veya senin repo adın)

### 4️⃣ Service Ayarları

**Basic Settings:**
- **Name:** `idrak-agora-token` (veya istediğin isim)
- **Region:** `Frankfurt (EU Central)` veya `London (UK)`
- **Branch:** `main` (veya `master`)
- **Root Directory:** `agora-token-server`
- **Runtime:** `Node`
- **Build Command:** `npm install`
- **Start Command:** `npm start`

**Instance Type:**
- **Plan:** `Free` (otomatik sleep oluyor ama bizim için yeterli)

### 5️⃣ Environment Variables Ekle

"Environment" sekmesinde bu 2 değişkeni ekle:

```
AGORA_APP_ID = 045bdb3866464fb6b47009e8044ce57e
AGORA_APP_CERTIFICATE = 0d55f75c1a5a48968ca941e880231003
```

⚠️ **ÖNEMLİ:** Bu değerleri Render.com dashboard'una gir, kod içinde kalmasınlar!

### 6️⃣ Deploy Et

1. "Create Web Service" butonuna tıkla
2. Render otomatik deploy başlatacak (2-3 dakika sürer)
3. Deploy bitince **URL'i kopyala** (örn: `https://idrak-agora-token.onrender.com`)

### 7️⃣ Flutter Kodunu Güncelle

`lib/services/agora_token_service.dart` dosyasını aç ve URL'i güncelle:

```dart
static const String _baseUrl = 'https://YOUR-SERVICE-NAME.onrender.com';
```

Örnek:
```dart
static const String _baseUrl = 'https://idrak-agora-token.onrender.com';
```

### 8️⃣ Test Et

```bash
# Flutter uygulamayı yeniden başlat
flutter run

# Meet'e gir ve test et
```

## 🧪 Manuel Test

Deploy edildikten sonra Postman veya curl ile test edebilirsin:

```bash
# Health check
curl https://YOUR-SERVICE-NAME.onrender.com/

# Token generate et
curl -X POST https://YOUR-SERVICE-NAME.onrender.com/generate-token \
  -H "Content-Type: application/json" \
  -d '{
    "channelName": "test-channel",
    "userId": "usr-test-123"
  }'
```

Başarılı response:
```json
{
  "token": "007eJxT...",
  "uid": 1234567,
  "expiresAt": 1788860000,
  "channelName": "test-channel"
}
```

## ⚡ Render Free Plan Notları

- **Sleep after 15 min inactivity** - İlk request 10-15 saniye geç gelebilir
- **750 saat/ay** - Sürekli açıksa 31 gün, yeterli!
- **100 GB bandwidth** - Token'lar küçük, sorun olmaz

## 🔄 Güncelleme Yapmak İsterseniz

1. Kodu güncelle
2. Git push yap
3. Render otomatik yeniden deploy eder!

## 🐛 Sorun Giderme

### Token alırken hata

1. Render dashboard → Logs sekmesine bak
2. Environment variables doğru mu kontrol et
3. Server çalışıyor mu: `https://YOUR-URL.onrender.com/` aç

### "Connection timeout" hatası

- Render free plan sleep modunda olabilir
- 10-15 saniye bekle, tekrar dene
- İlk request yavaş, sonrakiler hızlı olacak

### Invalid token hatası devam ederse

1. Backend loglarına bak
2. UID hesaplama algoritması aynı mı kontrol et
3. Token generation başarılı mı?

## 📞 Yardım

Sorun olursa Render logs'a bak:
```
Dashboard → Your Service → Logs
```

---

✅ **Artık güvenli token generation hazır!**
🎉 **App Certificate client-side'da yok!**
