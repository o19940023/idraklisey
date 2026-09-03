# Push Bildirişlər — Blaze-siz, Tam Pulsuz Quraşdırma

> **STATUS: CANLI (2026-09-01)**
> Worker: `https://idrak-push-relay.ramizmehdi9.workers.dev` (Cloudflare, ramizmehdi9@gmail.com)
> Secret-lər yüklənib, test push `all` topic-inə uğurla gedib.
> Tətbiq tərəfi: `lib/config/push_config.dart` (enabled=true).
> Yenidən deploy lazım olsa: `cd infra/push-relay && npx wrangler deploy`

Tətbiq **bağlı olsa belə** (Android + iOS) bildiriş çatdırma sistemi.
Firebase Blaze planı / Cloud Functions **tələb olunmur**.

## Necə işləyir

```
Tətbiqdə bildiriş göndərilir (admin/müəllim/ticket cavabı...)
        │
        ▼
Firestore-a yazılır (in-app gəmirçi qutusu — onsuz da işləyir)
        │  eyni anda
        ▼
Cloudflare Worker (PULSUZ relay)  ←  tətbiq POST atır
        │  service account açarı ilə
        ▼
FCM HTTP v1 API  →  topic-lər: user_..., role_..., staffrole_..., class_..., all
        │
        ▼
Cihazlar (tətbiq bağlı olsa belə sistem bildirişi göstərir)
```

- Abunəlik: hər istifadəçi girişdə öz topic-lərinə yazılır
  (`PushNotificationService` — hazır qoşulub).
- Göndərmə: `app_state.sendNotification` içindən relay-ə POST (`PushRelayService`).
- İOS-da çatdırılma üçün FCM APNs üzərindən işləyir (Addım 5 mütləqdir).

## Quraşdırma (bir dəfəlik, ~15 dəqiqə)

### Addım 1 — Firebase service account açarı

1. [Firebase Console](https://console.firebase.google.com) → **idraklisey-aafd7**
   → ⚙️ Project Settings → **Service accounts**.
2. **Generate new private key** → JSON faylı endirilir.
3. Fayldan bu iki sahəni götürürük: `client_email` və `private_key`.
   Faylı kiminləsə paylaşma, repoya atma!

### Addım 2 — Cloudflare hesabı (pulsuz, kart yoxdur)

1. [dash.cloudflare.com/sign-up](https://dash.cloudflare.com/sign-up) — e-poçtla qeydiyyat.
2. Kompüterdə terminalı aç:

```bash
cd infra/push-relay
npm install
npx wrangler login        # brauzer açılır, Cloudflare hesabına icazə ver
```

### Addım 3 — Secret-ləri yaz

Hər əmr ayrıca soruşacaq, daxil et + Enter:

```bash
npx wrangler secret put FIREBASE_CLIENT_EMAIL
# → firebase-adminsdk-xxxxx@idraklisey-aafd7.iam.gserviceaccount.com

npx wrangler secret put FIREBASE_PRIVATE_KEY
# → JSON-dakı private_key dəyərinin TAMAMI ("-----BEGIN" sətrindən "-----END" sətrinə qədər, \n-ləri birlikdə)

npx wrangler secret put PUSH_KEY
# → özün seçdiyin gizli açar, məs: openssl rand -hex 32 nəticəsi
```

### Addım 4 — Deploy et

```bash
npx wrangler deploy
```

Sonunda belə bir ünvan çıxır: `https://idrak-push-relay.<adın>.workers.dev`

### Addım 5 — iOS üçün APNs açarı (blok olmasın deyə əvvəlcədən)

1. [Apple Developer](https://developer.apple.com/account/resources/certificates/list)
   → Keys → **Create Key** → **Apple Push Notifications service (APNs)** seçili olsun → `.p8` fayl endir (Key ID + Team ID qeyd et).
2. Firebase Console → ⚙️ Project Settings → **Cloud Messaging** → **Apple app configuration** → APNs Authentication Key yüklə (Key ID və Team ID ilə).
3. Codemagic-də yenidən iOS build etmək lazım deyil — bu yalnız Firebase tərəfidir.

### Addım 6 — Tətbiqi relay-ə qoş

`lib/config/push_config.dart` faylını aç:

```dart
static const String relayUrl =
    'https://idrak-push-relay.<SENIN-ADIN>.workers.dev/send';
static const String relayKey = '<ADDIM 3-DƏki PUSH_KEY>';
static const bool enabled = true;   // false-dan true-a keçir
```

Tətbiqi yenidən build et (Codemagic / lokal).

### Addım 7 — Test

1. Bir telefona hesaba giriş et (məs. müəllim), bildiriş icazəsini qəbul et.
   Logda görəcəksən: `[Push] subscribed topics: [all, user_..., role_teacher, ...]`
2. Tətbiqi telefonda **tamamilə bağla** (swipe ilə sil).
3. Başqa cihazdan (məs. admin) müəllimə bildiriş göndər.
4. 5-10 saniyəyə telefonun bildiriş panelində görünməlidir.
   Lövhədə yoxlamalar: Cloudflare Dashboard → Workers → `idrak-push-relay` → Logs.

## Texniki detallar

- **Topic sxemi** (tətbiq ↔ worker birebir uyğun):
  | Topic | Kim abunə olur |
  |---|---|
  | `user_<userId>` | həmin istifadəçi |
  | `role_admin/teacher/student/parent` | həmin rol |
  | `staffrole_<rolId>` | işçi rolları (helpdesk, IT, psixoloq) |
  | `class_<sinif>` | şagirdlər + sinif müəllimi + **uşağı o sinifdə olan valideynlər** |
  | `all` | hamı (hədəf göstərilməyibsə) |
- Öz göndərdiyi bildiriş göndərənə gəlmir (`excludeUserId`).
- Worker pulsuz planda gündə 100 000 sorğuya qədər — məktəb üçün çox-çox bəsdir.
- Token OAuth2 1 saat cache-lənir; xərc sıfırdır.
- Alternativ (istifadə olunmur): `functions/index.js` — Cloud Functions yolu,
  Blaze tələb edir. `notification_listener_service.dart` — köhnə yarımçıq yanaşma,
  tətbiq bağlı ikən işləmir, silinə bilər.
