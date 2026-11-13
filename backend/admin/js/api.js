export async function api(method, path, body) {
  const opts = { method, headers: { 'X-Requested-With': 'wematch-admin' }, credentials: 'same-origin' };
  if (body instanceof FormData) opts.body = body;
  else if (body !== undefined) {
    opts.headers['Content-Type'] = 'application/json';
    opts.body = JSON.stringify(body);
  }
  const res = await fetch('/api/admin' + path, opts);
  const data = await res.json().catch(() => ({}));
  if (res.status === 401 && !path.startsWith('/auth/login')) {
    location.hash = '#/login';
    throw new Error('Please sign in');
  }
  if (!res.ok) throw new Error(data.error || 'Request failed');
  return data;
}
