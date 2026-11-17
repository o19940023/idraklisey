# idrak-push-relay

Blaze-siz push bildiriş relay-i (Cloudflare Worker, pulsuz plan).

Quraşdırma addımları: repo kökündəki [PUSH_SETUP.md](../../PUSH_SETUP.md)

```bash
npm install
npx wrangler login
npx wrangler secret put FIREBASE_CLIENT_EMAIL
npx wrangler secret put FIREBASE_PRIVATE_KEY
npx wrangler secret put PUSH_KEY
npx wrangler deploy
```
