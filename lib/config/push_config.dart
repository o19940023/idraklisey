/// Push relay (Cloudflare Worker) konfiqurasiyası.
///
/// Deploy edilib, CANLI (2026-09-01). Dəyişiklik lazım olsa:
/// worker kodu `infra/push-relay/` qovluğundadır,
/// ətraflı sənəd: PUSH_SETUP.md
class PushConfig {
  /// Öz serverimiz üzərindən birbaşa Push göndərmə endpointi (kənar workers.dev istifadə olunmur)
  static const String relayUrl =
      'https://new.idrak.edu.az/api/mobile/push-send';

  /// Serverdəki PUSH_KEY ilə eynidir.
  static const String relayKey =
      'ea74d0ee53767a0260a72a99b6dd1a3b2ce83c68f7cc6097';

  static const bool enabled = true;
}
