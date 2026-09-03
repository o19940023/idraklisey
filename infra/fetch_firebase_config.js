// Service account ilə real Firebase konfiqurasiyasını çəkir ( paving
// google-services.json + API açarları). Əl ilə Console-a girməyə ehtiyac yoxdur.
const crypto = require('crypto');
const fs = require('fs');

const SVC_FILE = 'idraklisey-aafd7-firebase-adminsdk-fbsvc-3b53328dd9.json';
const PROJECT_ID = 'idraklisey-aafd7';

async function getAccessToken() {
  const svc = JSON.parse(fs.readFileSync(SVC_FILE, 'utf8'));
  const now = Math.floor(Date.now() / 1000);
  const header = Buffer.from(JSON.stringify({ alg: 'RS256', typ: 'JWT' })).toString('base64url');
  const claims = Buffer.from(
    JSON.stringify({
      iss: svc.client_email,
      scope: 'https://www.googleapis.com/auth/firebase.readonly https://www.googleapis.com/auth/cloud-platform.read-only',
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
      exp: now + 3600,
    }),
  ).toString('base64url');
  const signer = crypto.createSign('RSA-SHA256');
  signer.update(`${header}.${claims}`);
  const sig = signer.sign(svc.private_key, 'base64url');
  const jwt = `${header}.${claims}.${sig}`;

  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });
  if (!res.ok) throw new Error(`token: ${res.status} ${await res.text()}`);
  return (await res.json()).access_token;
}

async function main() {
  const token = await getAccessToken();

  const apps = await fetch(
    `https://firebase.googleapis.com/v1beta1/projects/${PROJECT_ID}/androidApps`,
    { headers: { Authorization: `Bearer ${token}` } },
  );
  if (!apps.ok) throw new Error(`apps list: ${apps.status} ${await apps.text()}`);
  const list = (await apps.json()).apps || [];
  const target = list.find((a) => a.appId.includes(':android:'));
  if (!target) throw new Error('Android app tapılmadı');
  console.log('Android app:', target.displayName, target.packageName, target.appId);

  const cfgRes = await fetch(
    `https://firebase.googleapis.com/v1beta1/projects/${PROJECT_ID}/androidApps/${target.appId}/config`,
    { headers: { Authorization: `Bearer ${token}` } },
  );
  if (!cfgRes.ok) throw new Error(`config: ${cfgRes.status} ${await cfgRes.text()}`);
  const cfgText = Buffer.from((await cfgRes.json()).configFileContents, 'base64').toString('utf8');
  const cfg = JSON.parse(cfgText);
  const androidKey = cfg.client[0].api_key[0].current_key;
  console.log('REAL ANDROID API KEY:', androidKey);

  fs.writeFileSync('android/app/google-services.json', JSON.stringify(cfg, null, 2));
  console.log('✓ android/app/google-services.json yeniləndi');

  // Web app konfiqi (web + windows üçün)
  const webApps = await fetch(
    `https://firebase.googleapis.com/v1beta1/projects/${PROJECT_ID}/webApps`,
    { headers: { Authorization: `Bearer ${token}` } },
  );
  if (webApps.ok) {
    const wlist = (await webApps.json()).apps || [];
    if (wlist.length > 0) {
      const wcfgRes = await fetch(
        `https://firebase.googleapis.com/v1beta1/projects/${PROJECT_ID}/webApps/${wlist[0].appId}/config`,
        { headers: { Authorization: `Bearer ${token}` } },
      );
      if (wcfgRes.ok) {
        const wcfg = await wcfgRes.json();
        console.log('REAL WEB API KEY:', wcfg.apiKey);
        fs.writeFileSync('/tmp/web_config.json', JSON.stringify(wcfg, null, 2));
      }
    }
  }

  fs.writeFileSync('/tmp/android_key.txt', androidKey);
}

main().catch((e) => {
  console.error('XƏTA:', e.message);
  process.exit(1);
});
