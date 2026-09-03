/**
 * İdrak Liseyi — Push Relay (Cloudflare Worker, pulsuz plan)
 *
 * Tətbiq bildiriş göndərəndə buraya POST atır, bu worker service account
 * açarı ilə FCM HTTP v1 API-yə qoşulub topic-lərə push göndərir.
 * Cloud Functions / Blaze plan TƏLƏB ETMİR.
 *
 * Topic sxemi tətbiqdəki PushNotificationService._topicsFor ilə eynidir:
 *   user_<id>          → konkret istifadəçi
 *   role_<rolEnum>     → admin / teacher / student / parent
 *   staffrole_<rolId>  → işçi rolları ('role-' prefiksi ilə gələn hədəflər)
 *   class_<sinif>      → sinif
 *   all                → hamı (hədəf yoxdursa)
 */

const FCM_SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';
const TOKEN_URL = 'https://oauth2.googleapis.com/token';

let cachedToken = null; // { token, expiresAt }

function b64urlFromJson(obj) {
  return btoa(JSON.stringify(obj))
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

function strB64url(str) {
  return btoa(str)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

// Firebase service account private key-i WebCrypto üçün hazırla
function privateKeyToBytes(pem) {
  const body = pem
    .replace(/-----BEGIN PRIVATE KEY-----/g, '')
    .replace(/-----END PRIVATE KEY-----/g, '')
    .replace(/\\n/g, '\n')
    .replace(/\s+/g, '');
  const bin = atob(body);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return bytes;
}

async function getAccessToken(env) {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.expiresAt > now + 60) {
    return cachedToken.token;
  }

  const header = b64urlFromJson({ alg: 'RS256', typ: 'JWT' });
  const claims = b64urlFromJson({
    iss: env.FIREBASE_CLIENT_EMAIL,
    scope: FCM_SCOPE,
    aud: TOKEN_URL,
    iat: now,
    exp: now + 3600,
  });
  const unsigned = `${header}.${claims}`;

  const key = await crypto.subtle.importKey(
    'pkcs8',
    privateKeyToBytes(env.FIREBASE_PRIVATE_KEY),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const sig = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    new TextEncoder().encode(unsigned),
  );
  const sigB64 = strB64url(String.fromCharCode(...new Uint8Array(sig)));
  const jwt = `${unsigned}.${sigB64}`;

  const res = await fetch(TOKEN_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });
  if (!res.ok) {
    throw new Error(`Token xətası: ${res.status} ${await res.text()}`);
  }
  const data = await res.json();
  cachedToken = { token: data.access_token, expiresAt: now + (data.expires_in || 3600) };
  return cachedToken.token;
}

// Tətbiqdəki _sanitize ilə eyni: FCM topic yalnız [a-zA-Z0-9-_.~%] qəbul edir
function sanitize(raw) {
  const cleaned = String(raw).replace(/[^a-zA-Z0-9\-_.~%]/g, '_');
  return cleaned.length > 200 ? cleaned.substring(0, 200) : cleaned;
}

// Hədəf sahələrindən FCM topic-ləri (tətbiqin abunə sxemi ilə birebir)
function topicsFor(payload) {
  const topics = new Set();

  for (const uid of payload.targetUserIds || []) {
    if (uid && uid !== payload.excludeUserId) topics.add(`user_${sanitize(uid)}`);
  }
  for (const role of payload.targetRoles || []) {
    if (!role) continue;
    // 'role-helpdesk' kimi işçi rol id-ləri tətbiqdə staffrole_ topic-i ilə abunə olunur
    if (String(role).startsWith('role-')) {
      topics.add(`staffrole_${sanitize(role)}`);
    } else {
      topics.add(`role_${sanitize(role)}`);
    }
  }
  for (const cls of payload.targetClasses || []) {
    if (cls && String(cls).trim()) topics.add(`class_${sanitize(cls.trim())}`);
  }
  if (payload.targetStudentId) {
    topics.add(`user_${sanitize(payload.targetStudentId)}`);
  }
  if (payload.targetParentId) {
    topics.add(`user_${sanitize(payload.targetParentId)}`);
  }
  if (topics.size === 0) topics.add('all');

  return [...topics];
}

function buildMessage(payload, topic) {
  const urgent = payload.priority === 'urgent';
  return {
    message: {
      topic: topic,
      notification: {
        title: payload.title || 'İdrak Liseyi',
        body: payload.body || '',
      },
      data: {
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        priority: payload.priority || 'normal',
        senderId: payload.excludeUserId || '',
      },
      android: {
        priority: urgent ? 'high' : 'normal',
        notification: {
          channel_id: 'idrak_general',
          sound: 'default',
          notification_priority: urgent ? 'PRIORITY_MAX' : 'PRIORITY_HIGH',
          visibility: urgent ? 'PUBLIC' : 'PRIVATE',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
            'thread-id': payload.category || 'general',
          },
        },
      },
    },
  };
}

export default {
  async fetch(request, env) {
    if (request.method !== 'POST') {
      return json({ error: 'Yalnız POST' }, 405);
    }
    if (request.headers.get('X-Push-Key') !== env.PUSH_KEY) {
      return json({ error: 'İcazə yoxdur' }, 401);
    }

    let payload;
    try {
      payload = await request.json();
    } catch (_) {
      return json({ error: 'Yanlış JSON' }, 400);
    }
    if (!payload.title || !payload.body) {
      return json({ error: 'title və body tələb olunur' }, 400);
    }

    let accessToken;
    try {
      accessToken = await getAccessToken(env);
    } catch (e) {
      return json({ error: String(e.message || e) }, 500);
    }

    const topics = topicsFor(payload);
    const results = await Promise.all(
      topics.map(async (topic) => {
        try {
          const res = await fetch(
            `https://fcm.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/messages:send`,
            {
              method: 'POST',
              headers: {
                Authorization: `Bearer ${accessToken}`,
                'Content-Type': 'application/json',
              },
              body: JSON.stringify(buildMessage(payload, topic)),
            },
          );
          if (!res.ok) {
            return { topic, ok: false, detail: (await res.text()).slice(0, 300) };
          }
          return { topic, ok: true };
        } catch (e) {
          return { topic, ok: false, detail: String(e) };
        }
      }),
    );

    const sent = results.filter((r) => r.ok).length;
    return json({ sent, total: topics.length, details: results }, 200);
  },
};

function json(obj, status) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}
