/// Push relay (Cloudflare Worker) konfiqurasiyası.
///
/// Deploy edilib, CANLI (2026-09-01). Dəyişiklik lazım olsa:
/// worker kodu `infra/push-relay/` qovluğundadır,
/// ətraflı sənəd: PUSH_SETUP.md
class PushConfig {
  /// Deployed worker: `npx wrangler deploy` (infra/push-relay)
  static const String relayUrl =
      'https://idrak-push-relay.ramizmehdi9.workers.dev/send';

  /// Worker-dəki PUSH_KEY secret-i ilə eynidir.
  static const String relayKey =
      'ea74d0ee53767a0260a72a99b6dd1a3b2ce83c68f7cc6097';

  /// Relay canlıdır.
  static const bool enabled = true;
}
