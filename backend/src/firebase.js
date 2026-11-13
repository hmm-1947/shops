import jwt from 'jsonwebtoken';
import { config } from './config.js';
import { HttpError } from './errors.js';

const CERT_URL = 'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';
let certs = { keys: {}, expires: 0 };

async function loadCerts() {
  if (Date.now() < certs.expires) return certs.keys;
  const res = await fetch(CERT_URL, { signal: AbortSignal.timeout(8000) });
  if (!res.ok) throw new Error('Could not load Firebase certificates');
  const maxAge = /max-age=(\d+)/.exec(res.headers.get('cache-control') ?? '')?.[1];
  certs = { keys: await res.json(), expires: Date.now() + Number(maxAge ?? 3600) * 1000 };
  return certs.keys;
}

export async function verifyFirebaseToken(token) {
  if (!config.firebaseProjectId) throw new HttpError(503, 'Customer sign-in is not configured on the server');
  const decoded = jwt.decode(token, { complete: true });
  const cert = (await loadCerts())[decoded?.header?.kid];
  if (!cert) throw new HttpError(401, 'Unauthorized');
  try {
    return jwt.verify(token, cert, {
      algorithms: ['RS256'],
      audience: config.firebaseProjectId,
      issuer: `https://securetoken.google.com/${config.firebaseProjectId}`,
    });
  } catch {
    throw new HttpError(401, 'Unauthorized');
  }
}

export async function requireCustomer(req, res, next) {
  try {
    const m = /^Bearer (.+)$/.exec(req.get('authorization') ?? '');
    if (!m) throw new HttpError(401, 'Unauthorized');
    const c = await verifyFirebaseToken(m[1]);
    if (!c.sub) throw new HttpError(401, 'Unauthorized');
    req.customer = { uid: c.sub, name: c.name ?? '', email: c.email ?? '' };
    next();
  } catch (e) {
    next(e);
  }
}
