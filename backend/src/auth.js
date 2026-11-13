import jwt from 'jsonwebtoken';
import { config } from './config.js';

export const COOKIE = config.prod ? '__Host-wm_admin' : 'wm_admin';

export const cookieOptions = {
  httpOnly: true,
  sameSite: 'strict',
  secure: config.prod,
  path: '/',
  maxAge: 2 * 60 * 60 * 1000,
};

export const signToken = (adminId) => jwt.sign({ sub: adminId }, config.jwtSecret, { algorithm: 'HS256', expiresIn: '2h' });

export function requireAdmin(req, res, next) {
  try {
    req.admin = jwt.verify(req.cookies?.[COOKIE] ?? '', config.jwtSecret, { algorithms: ['HS256'] });
    next();
  } catch {
    res.status(401).json({ error: 'Unauthorized' });
  }
}

export function csrfGuard(req, res, next) {
  if (!['GET', 'HEAD', 'OPTIONS'].includes(req.method) && req.get('x-requested-with') !== 'wematch-admin') {
    return res.status(403).json({ error: 'Forbidden' });
  }
  next();
}
