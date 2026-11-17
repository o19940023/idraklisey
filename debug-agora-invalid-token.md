# Debug Session: agora-invalid-token
- **Status**: [OPEN]
- **Issue**: Agora kanala basariyla katilmis gibi gorunse de hemen ardindan `ErrorCodeType.errInvalidToken` donuyor; tekrar baglanma denemeleri `AgoraRtcException(-17, null)` ile cakisiyor.
- **Debug Server**: http://10.10.15.114:7777/event
- **Log File**: .dbg/trae-debug-log-agora-invalid-token.ndjson

## Reproduction Steps
1. Meet Idrak ekranindan goruntulu odayi ac.
2. Odaya katilma tamamlandiktan hemen sonra Agora hata akisina bak.
3. `errInvalidToken`, `onRequestToken`, yeniden baglanma ve `AgoraRtcException(-17, null)` siralamasini gozlemle.

## Hypotheses & Verification
| ID | Hypothesis | Likelihood | Effort | Evidence |
|----|------------|------------|--------|----------|
| A | Token binary layout hala Agora AccessToken2 beklentisiyle uyusmuyor | High | Low | Pending |
| B | App certificate HMAC anahtari yanlis bicimde kullaniliyor | High | Low | Pending |
| C | `uid` veya `channelName` ile token icindeki degerler `joinChannel` parametreleriyle birebir eslesmiyor | Medium | Low | Pending |
| D | `errInvalidToken` sonrasi paralel rejoin/renew akisları ikinci bir hata zinciri uretiyor, ancak kok neden token uretimi | High | Low | Pending |
| E | Dashboard tarafinda App ID / certificate eslesmesi veya primary certificate durumu farkli | Medium | Medium | Pending |

## Log Evidence
- User logu: kanal basariyla katildi bildirimi sonrasi aninda `errInvalidToken`.
- User logu: tekrar token isteme ve rejoin dongusu sonrasi `AgoraRtcException(-17, null)`.
- Instrumentation added in `lib/services/agora_token_generator.dart` and `lib/services/agora_service.dart`.

## Verification Conclusion
Pending instrumentation and runtime evidence collection.
