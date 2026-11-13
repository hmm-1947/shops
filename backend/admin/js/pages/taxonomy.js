import { h, toast, modal, field, thumb, badge, guard } from '../ui.js';
import { api } from '../api.js';

function taxonomyPage({ title, path, parent, discount }) {
  return async function page(main) {
    const [rows, parents] = await Promise.all([api('GET', path), parent ? api('GET', parent.path) : []]);
    const reload = () => guard(() => page(main));

    const save = async (row, fd) => {
      await api(row ? 'PUT' : 'POST', row ? path + '/' + row.id : path, fd);
      toast('Saved');
      reload();
    };

    const toggle = (row) =>
      guard(() => {
        const fd = new FormData();
        fd.set('name', row.name);
        fd.set('enabled', !row.enabled);
        if (parent) fd.set(parent.key, row[parent.key]);
        if (discount) fd.set('discount', row.discount);
        return save(row, fd);
      });

    function edit(row) {
      const name = h('input', { required: true, maxlength: 80, value: row?.name ?? '' });
      const sel = parent && h('select', { required: true }, parents.map((p) => h('option', { value: p.id, selected: p.id === row?.[parent.key] }, p.name)));
      const disc = discount && h('input', { type: 'number', min: 0, max: 100, step: '0.01', required: true, value: row?.discount ?? 0 });
      const file = h('input', { type: 'file', accept: 'image/jpeg,image/png,image/webp,image/gif,image/avif', required: !row });
      const en = h('input', { type: 'checkbox', checked: row ? !!row.enabled : true });
      const form = h(
        'form',
        {
          onsubmit: (e) => {
            e.preventDefault();
            const fd = new FormData();
            fd.set('name', name.value);
            fd.set('enabled', en.checked);
            if (sel) fd.set(parent.key, sel.value);
            if (disc) fd.set('discount', disc.value);
            if (file.files[0]) fd.set('image', file.files[0]);
            guard(async () => {
              await save(row, fd);
              close();
            });
          },
        },
        field('Name', name),
        sel && field(parent.label, sel),
        disc && field('Discount %', disc, discount.hint),
        field('Image', file, row ? 'Leave empty to keep the current image. Converted to WebP automatically.' : 'Converted to WebP automatically.'),
        h('label', { class: 'inline' }, en, 'Enabled'),
        h('div', { class: 'row end' }, h('button', { class: 'btn', type: 'submit' }, 'Save')),
      );
      const close = modal((row ? 'Edit ' : 'Add ') + title.toLowerCase(), form);
    }

    const heads = ['Image', 'Name', parent && parent.label, discount && 'Discount', 'Status', ''].filter(Boolean);
    main.replaceChildren(
      h('div', { class: 'head' }, h('h1', {}, title), h('button', { class: 'btn', onclick: () => edit() }, 'Add')),
      h(
        'table',
        {},
        h('thead', {}, h('tr', {}, heads.map((t) => h('th', {}, t)))),
        h(
          'tbody',
          {},
          rows.map((r) =>
            h(
              'tr',
              {},
              h('td', {}, thumb(r.image, r.name)),
              h('td', {}, r.name),
              parent && h('td', {}, r[parent.nameKey]),
              discount && h('td', {}, r.discount + '%'),
              h('td', {}, badge(r.enabled)),
              h('td', { class: 'row end' }, h('button', { class: 'btn ghost sm', onclick: () => edit(r) }, 'Edit'), h('button', { class: 'btn ghost sm', onclick: () => toggle(r) }, r.enabled ? 'Disable' : 'Enable')),
            ),
          ),
        ),
      ),
    );
  };
}

export const categories = taxonomyPage({ title: 'Categories', path: '/categories', discount: { hint: 'Overrides the variant discount of every product in this category (a brand discount still wins).' } });
export const subcategories = taxonomyPage({ title: 'Subcategories', path: '/subcategories', parent: { key: 'category_id', label: 'Category', path: '/categories', nameKey: 'category_name' } });
export const brands = taxonomyPage({ title: 'Brands', path: '/brands', discount: { hint: 'Highest priority: overrides category and variant discounts.' } });
