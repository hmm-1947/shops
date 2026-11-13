export function h(tag, props = {}, ...kids) {
  const el = document.createElement(tag);
  for (const [k, v] of Object.entries(props ?? {})) {
    if (k.startsWith('on')) el.addEventListener(k.slice(2).toLowerCase(), v);
    else if (k === 'class') el.className = v;
    else if (v === true) el.setAttribute(k, '');
    else if (v !== false && v != null) el.setAttribute(k, v);
  }
  el.append(...kids.flat(Infinity).filter((k) => k != null && k !== false));
  return el;
}

export function toast(msg, bad = false) {
  const t = h('div', { class: 'toast' + (bad ? ' bad' : '') }, msg);
  document.getElementById('toast').append(t);
  setTimeout(() => t.remove(), 3500);
}

export function modal(title, ...body) {
  const close = () => overlay.remove();
  const overlay = h(
    'div',
    { class: 'overlay', onclick: (e) => e.target === overlay && close() },
    h(
      'div',
      { class: 'modal wide', role: 'dialog', 'aria-modal': 'true', 'aria-label': title },
      h('div', { class: 'modal-head' }, h('h3', {}, title), h('button', { class: 'btn ghost sm', type: 'button', 'aria-label': 'Close', onclick: close }, 'Close')),
      body,
    ),
  );
  document.body.append(overlay);
  return close;
}

export const confirmBox = (msg) =>
  new Promise((resolve) => {
    const done = (v) => () => {
      close();
      resolve(v);
    };
    const close = modal('Confirm', h('p', {}, msg), h('div', { class: 'row end' }, h('button', { class: 'btn ghost', onclick: done(false) }, 'Cancel'), h('button', { class: 'btn danger', onclick: done(true) }, 'Confirm')));
  });

export const field = (label, input, hint) => h('label', { class: 'f' }, h('span', {}, label), input, hint && h('div', { class: 'hint' }, hint));

export const thumb = (src, alt) => h('img', { class: 'thumb', src, alt, loading: 'lazy' });

export const badge = (on, yes = 'Enabled', no = 'Disabled') => h('span', { class: 'badge' + (on ? ' on' : '') }, on ? yes : no);

export const rupees = (paise) => (paise / 100).toFixed(2);

export async function guard(fn) {
  try {
    return await fn();
  } catch (e) {
    toast(e.message, true);
  }
}
