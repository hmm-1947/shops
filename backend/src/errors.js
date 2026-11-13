export class HttpError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

export function parse(schema, data) {
  const r = schema.safeParse(data);
  if (!r.success) {
    const i = r.error.issues[0];
    throw new HttpError(400, `${i.path.join('.') || 'body'}: ${i.message}`);
  }
  return r.data;
}

export function pid(v) {
  const n = Number(v);
  if (!Number.isInteger(n) || n < 1) throw new HttpError(404, 'Not found');
  return n;
}

export const notFound = (req, res) => res.status(404).json({ error: 'Not found' });

export function errorHandler(err, req, res, next) {
  if (err instanceof HttpError) return res.status(err.status).json({ error: err.message });
  if (err.name === 'MulterError') return res.status(400).json({ error: err.message });
  if (err.type === 'entity.parse.failed' || err.type === 'entity.too.large') {
    return res.status(400).json({ error: 'Invalid request body' });
  }
  const m = String(err.message);
  if (m.includes('UNIQUE')) return res.status(409).json({ error: 'Already exists' });
  if (m.includes('FOREIGN KEY')) return res.status(409).json({ error: 'Invalid or in-use reference' });
  console.error(err);
  res.status(500).json({ error: 'Server error' });
}
