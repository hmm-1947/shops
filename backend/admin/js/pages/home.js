import { h, toast, modal, field, badge, confirmBox, guard } from '../ui.js';
import { api } from '../api.js';

const TARGETS = { category: '/categories', subcategory: '/subcategories', brand: '/brands', carousel: '/carousels' };

export default async function homeLayout(main) {
  const rows = await api('GET', '/item-classes');
  const reload = () => guard(() => homeLayout(main));

  const move = (i, d) =>
    guard(async () => {
      const ids = rows.map((r) => r.id);
      [ids[i], ids[i + d]] = [ids[i + d], ids[i]];
      await api('POST', '/item-classes/reorder', { ids });
      await homeLayout(main);
    });

  async function edit(id) {
    const ic = id ? await api('GET', '/item-classes/' + id) : { name: '', display: 'scroll', columns: 2, view_all_after: 6, map_type: 'products', map_id: null, enabled: true, products: [] };
    const chosen = new Map(ic.products.map((p) => [p.id, p.name]));
    const cache = {};

    const name = h('input', { required: true, maxlength: 80, value: ic.name });
    const display = h('select', {}, ['scroll', 'list'].map((v) => h('option', { value: v, selected: v === ic.display }, v === 'scroll' ? 'Scroll (horizontal)' : 'List (vertical)')));
    const columns = h('select', {}, [2, 4].map((n) => h('option', { value: n, selected: n === ic.columns }, n + ' columns')));
    const after = h('input', { type: 'number', min: 1, max: 50, value: ic.view_all_after });
    const listOpts = h('div', {}, field('Columns', columns), field('Products before "View all"', after));
    const enabled = h('input', { type: 'checkbox', checked: !!ic.enabled });
    const mapType = h('select', {}, [['products', 'Selected products'], ['category', 'Category'], ['subcategory', 'Subcategory'], ['brand', 'Brand'], ['carousel', 'Carousel']].map(([v, l]) => h('option', { value: v, selected: v === ic.map_type }, l)));
    const target = h('div');
    let targetSelect;

    const syncDisplay = () => (listOpts.hidden = display.value !== 'list');
    display.addEventListener('change', syncDisplay);
    syncDisplay();

    async function drawTarget() {
      targetSelect = null;
      if (mapType.value === 'products') return drawPicker();
      const path = TARGETS[mapType.value];
      cache[path] ??= await api('GET', path);
      targetSelect = h('select', { required: true }, [h('option', { value: '' }, 'Select...'), ...cache[path].map((r) => h('option', { value: r.id, selected: r.id === ic.map_id && mapType.value === ic.map_type }, r.name))]);
      target.replaceChildren(field('Map to', targetSelect));
    }

    function drawPicker() {
      const chips = h('div', { class: 'chips' });
      const results = h('div', { class: 'results' });
      const drawChips = () =>
        chips.replaceChildren(...[...chosen].map(([pid, pname]) => h('span', { class: 'chip' }, pname, h('button', { type: 'button', 'aria-label': 'Remove ' + pname, onclick: () => { chosen.delete(pid); drawChips(); } }, '✕'))));
      const search = h('input', { type: 'search', placeholder: 'Search live products to add', maxlength: 100 });
      let timer;
      search.addEventListener('input', () => {
        clearTimeout(timer);
        timer = setTimeout(
          () =>
            guard(async () => {
              const { items } = await api('GET', '/products?status=active&limit=10&q=' + encodeURIComponent(search.value));
              results.replaceChildren(...items.map((p) => h('div', {}, p.name, h('button', { class: 'btn sm', type: 'button', onclick: () => { chosen.set(p.id, p.name); drawChips(); } }, 'Add'))));
            }),
          300,
        );
      });
      drawChips();
      target.replaceChildren(h('div', { class: 'f' }, h('span', { class: 'hint' }, 'Products (shown in the order added)'), chips, search, results));
    }

    mapType.addEventListener('change', () => guard(drawTarget));
    await drawTarget();

    const form = h(
      'form',
      {
        onsubmit: (e) => {
          e.preventDefault();
          guard(async () => {
            const manual = mapType.value === 'products';
            await api(id ? 'PUT' : 'POST', '/item-classes' + (id ? '/' + id : ''), {
              name: name.value,
              display: display.value,
              columns: Number(columns.value),
              view_all_after: Number(after.value) || 6,
              map_type: mapType.value,
              map_id: manual ? null : Number(targetSelect.value) || null,
              product_ids: manual ? [...chosen.keys()] : [],
              enabled: enabled.checked,
            });
            close();
            toast('Saved');
            reload();
          });
        },
      },
      field('Name', name),
      field('Display', display),
      listOpts,
      field('Mapping type (one per item class)', mapType),
      target,
      h('label', { class: 'inline' }, enabled, 'Enabled'),
      h('div', { class: 'row end' }, h('button', { class: 'btn', type: 'submit' }, 'Save')),
    );
    const close = modal(id ? 'Edit item class' : 'New item class', form);
  }

  main.replaceChildren(
    h('div', { class: 'head' }, h('h1', {}, 'Home page arrangement'), h('button', { class: 'btn', onclick: () => guard(() => edit()) }, 'New item class')),
    h('p', { class: 'hint' }, 'The mobile app home page shows enabled item classes in this order.'),
    h(
      'table',
      {},
      h('thead', {}, h('tr', {}, ['#', 'Name', 'Display', 'Mapped to', 'Status', 'Order', ''].map((t) => h('th', {}, t)))),
      h(
        'tbody',
        {},
        rows.map((r, i) =>
          h(
            'tr',
            {},
            h('td', {}, i + 1),
            h('td', {}, r.name),
            h('td', {}, r.display === 'list' ? 'List, ' + r.columns + ' col, ' + r.view_all_after + ' before View all' : 'Scroll'),
            h('td', {}, r.map_type + ': ' + (r.map_label ?? '-')),
            h('td', {}, badge(r.enabled)),
            h(
              'td',
              { class: 'row' },
              h('button', { class: 'btn ghost sm', disabled: i === 0, 'aria-label': 'Move up', onclick: () => move(i, -1) }, 'Up'),
              h('button', { class: 'btn ghost sm', disabled: i === rows.length - 1, 'aria-label': 'Move down', onclick: () => move(i, 1) }, 'Down'),
            ),
            h(
              'td',
              {},
              h('div', { class: 'row end' }, h('button', { class: 'btn ghost sm', onclick: () => guard(() => edit(r.id)) }, 'Edit'), h('button', {
                class: 'btn danger sm',
                onclick: () =>
                  guard(async () => {
                    if (!(await confirmBox('Delete "' + r.name + '"?'))) return;
                    await api('DELETE', '/item-classes/' + r.id);
                    toast('Deleted');
                    await homeLayout(main);
                  }),
              }, 'Delete')),
            ),
          ),
        ),
      ),
    ),
  );
}
