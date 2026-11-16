import { h, toast, icon, badge, guard, confirmBox } from '../ui.js';
import { api } from '../api.js';

export default async function displayBrand(main) {
  const [brands, cur] = await Promise.all([api('GET', '/brands'), api('GET', '/display-brand')]);
  let selected = brands.find((b) => b.id === cur.brand_id) ?? null;
  let open = false;
  let query = '';

  const root = h('div', { class: 'dd' });
  const preview = h('div', { class: 'card' });

  const logo = (b, cls = '') => h('img', { class: 'dd-logo ' + cls, src: b.image, alt: '', loading: 'lazy' });

  async function save(brandId) {
    await api('PUT', '/display-brand', { brand_id: brandId });
    selected = brands.find((b) => b.id === brandId) ?? null;
    toast(selected ? 'Display brand set to ' + selected.name : 'Display brand removed');
    close();
    drawPreview();
  }

  function onDocClick(e) {
    if (!root.contains(e.target)) close();
  }
  function onKey(e) {
    if (e.key === 'Escape') {
      close();
      root.querySelector('.dd-btn')?.focus();
    }
  }
  function close() {
    open = false;
    query = '';
    document.removeEventListener('mousedown', onDocClick);
    document.removeEventListener('keydown', onKey);
    drawDropdown();
  }
  function toggle() {
    if (open) return close();
    open = true;
    document.addEventListener('mousedown', onDocClick);
    document.addEventListener('keydown', onKey);
    drawDropdown();
    root.querySelector('.dd-search')?.focus();
  }

  function drawDropdown() {
    const btn = h(
      'button',
      { class: 'dd-btn', type: 'button', 'aria-haspopup': 'listbox', 'aria-expanded': String(open), onclick: toggle },
      selected ? logo(selected) : h('span', { class: 'dd-logo dd-empty' }),
      h('span', { class: 'dd-name' + (selected ? '' : ' muted') }, selected ? selected.name : 'Select a brand'),
      h('span', { class: 'dd-chev' + (open ? ' up' : '') }, icon('chevron')),
    );
    const kids = [btn];
    if (open) {
      const list = h('div', { class: 'dd-list', role: 'listbox' });
      const paint = () => {
        const q = query.trim().toLowerCase();
        const rows = brands.filter((b) => b.name.toLowerCase().includes(q));
        list.replaceChildren(
          ...(rows.length
            ? rows.map((b) =>
                h(
                  'button',
                  { class: 'dd-opt' + (selected?.id === b.id ? ' sel' : ''), type: 'button', role: 'option', 'aria-selected': String(selected?.id === b.id), onclick: () => guard(() => save(b.id)) },
                  logo(b),
                  h('span', { class: 'dd-name' }, b.name),
                  !b.enabled && badge(false, '', 'Disabled'),
                  selected?.id === b.id && h('span', { class: 'dd-check' }, icon('check')),
                ),
              )
            : [h('div', { class: 'dd-none' }, brands.length ? 'No brands match' : 'No brands yet. Add one on the Brands page.')]),
        );
      };
      const search = h('input', {
        class: 'dd-search',
        type: 'search',
        placeholder: 'Search brands',
        'aria-label': 'Search brands',
        oninput: (e) => {
          query = e.target.value;
          paint();
        },
      });
      paint();
      kids.push(h('div', { class: 'dd-menu' }, search, list));
    }
    root.replaceChildren(...kids);
  }

  function drawPreview() {
    const off = selected && !selected.enabled;
    preview.replaceChildren(
      h('h2', {}, 'Preview'),
      selected
        ? h(
            'div',
            {},
            h('div', { class: 'dd-pill' }, logo(selected, 'big'), h('span', {}, selected.name)),
            h('p', { class: 'hint' }, off ? 'This brand is disabled, so nothing will show in the app until you enable it or pick another brand.' : 'Shown in the app navigation bar after Cafe. Tapping it lists only this brand\'s products.'),
            h(
              'div',
              { class: 'row end' },
              h(
                'button',
                {
                  class: 'btn danger sm',
                  onclick: () =>
                    guard(async () => {
                      if (await confirmBox('Remove the display brand from the app navigation bar?')) await save(null);
                    }),
                },
                'Remove display brand',
              ),
            ),
          )
        : h('p', { class: 'hint' }, 'No display brand selected. Nothing is shown in the app navigation bar.'),
    );
  }

  drawDropdown();
  drawPreview();
  main.replaceChildren(
    h('div', { class: 'head' }, h('h1', {}, 'Display brand')),
    h('p', { class: 'hint' }, 'Pick one brand to feature in the app\'s bottom navigation bar after Cafe. It uses the brand\'s existing logo.'),
    h('div', { class: 'card' }, h('span', { class: 'hint' }, 'Featured brand'), root),
    preview,
  );
}
