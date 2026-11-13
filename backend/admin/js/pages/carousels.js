import { h, toast, field, thumb, badge, confirmBox, guard } from '../ui.js';
import { api } from '../api.js';

export async function carousels(main) {
  const rows = await api('GET', '/carousels');
  const name = h('input', { required: true, maxlength: 80, placeholder: 'New carousel name', 'aria-label': 'Carousel name' });
  main.replaceChildren(
    h('div', { class: 'head' }, h('h1', {}, 'Carousels')),
    h(
      'form',
      {
        class: 'card row',
        onsubmit: (e) => {
          e.preventDefault();
          guard(async () => {
            const { id } = await api('POST', '/carousels', { name: name.value, enabled: true });
            location.hash = '#/carousels/' + id;
          });
        },
      },
      name,
      h('button', { class: 'btn', type: 'submit' }, 'Create'),
    ),
    h(
      'table',
      {},
      h('thead', {}, h('tr', {}, ['Name', 'Images', 'Status', ''].map((t) => h('th', {}, t)))),
      h('tbody', {}, rows.map((c) => h('tr', {}, h('td', {}, c.name), h('td', {}, c.image_count), h('td', {}, badge(c.enabled)), h('td', { class: 'row end' }, h('a', { class: 'btn ghost sm', href: '#/carousels/' + c.id }, 'Manage'))))),
    ),
  );
}

export async function carouselEdit(main, id) {
  const c = await api('GET', '/carousels/' + id);
  const name = h('input', { required: true, maxlength: 80, value: c.name });
  const enabled = h('input', { type: 'checkbox', checked: c.enabled });
  const grid = h('div', { class: 'grid' });

  const draw = (list) =>
    grid.replaceChildren(
      ...list.map((im) =>
        h(
          'div',
          { class: 'tile' },
          h('img', { src: im.image, alt: c.name }),
          h('button', { class: 'btn danger sm', onclick: () => guard(async () => draw((await api('DELETE', '/carousels/' + id + '/images/' + im.id)).images)) }, 'Delete'),
        ),
      ),
    );
  draw(c.images);

  const files = h('input', {
    type: 'file',
    multiple: true,
    accept: 'image/jpeg,image/png,image/webp,image/gif,image/avif',
    onchange: () =>
      guard(async () => {
        const fd = new FormData();
        for (const f of files.files) fd.append('images', f);
        draw((await api('POST', '/carousels/' + id + '/images', fd)).images);
        files.value = '';
        toast('Images uploaded');
      }),
  });

  main.replaceChildren(
    h('div', { class: 'head' }, h('h1', {}, 'Carousel'), h('a', { class: 'btn ghost', href: '#/carousels' }, 'Back')),
    h(
      'form',
      {
        class: 'card',
        onsubmit: (e) => {
          e.preventDefault();
          guard(async () => {
            await api('PUT', '/carousels/' + id, { name: name.value, enabled: enabled.checked });
            toast('Saved');
          });
        },
      },
      field('Name', name),
      h('label', { class: 'inline' }, enabled, 'Enabled'),
      h('div', { class: 'row end' }, h('button', { class: 'btn', type: 'submit' }, 'Save')),
    ),
    h('div', { class: 'card' }, h('h2', {}, 'Images'), grid, field('Add images', files, 'Converted to WebP automatically.')),
    h(
      'button',
      {
        class: 'btn danger',
        onclick: () =>
          guard(async () => {
            if (!(await confirmBox('Delete this carousel and its images?'))) return;
            await api('DELETE', '/carousels/' + id);
            location.hash = '#/carousels';
          }),
      },
      'Delete carousel',
    ),
  );
}
