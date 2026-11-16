import { h, toast, field, confirmBox, guard } from '../ui.js';
import { api } from '../api.js';

const typeSelect = (value) =>
  h('select', { 'aria-label': 'Charge type' }, [
    h('option', { value: 'fixed', selected: value === 'fixed' }, 'Fixed amount (₹)'),
    h('option', { value: 'percent', selected: value === 'percent' }, 'Percentage of order total (%)'),
  ]);

const payload = (name, value, type, enabled) => ({ name: name.value, value: Number(value.value), type: type.value, enabled: enabled.checked });

export default async function charges(main) {
  const rows = await api('GET', '/charges');

  const name = h('input', { required: true, maxlength: 80, placeholder: 'e.g. GST, Handling charge', 'aria-label': 'Charge name' });
  const value = h('input', { required: true, type: 'number', min: 0, step: '0.01', placeholder: 'Value', 'aria-label': 'Charge value' });
  const type = typeSelect('fixed');
  const enabled = h('input', { type: 'checkbox', checked: true });

  main.replaceChildren(
    h('div', { class: 'head' }, h('h1', {}, 'Charges & configurations')),
    h('p', { class: 'hint' }, 'Enabled charges are added to the order total shown to customers. Percentages apply to the item total (before delivery fee).'),
    h(
      'form',
      {
        class: 'card',
        onsubmit: (e) => {
          e.preventDefault();
          guard(async () => {
            await api('POST', '/charges', payload(name, value, type, enabled));
            toast('Charge added');
            await charges(main);
          });
        },
      },
      h('h2', {}, 'Add charge'),
      h('div', { class: 'row' }, field('Name', name), field('Value', value), field('Type', type), h('label', { class: 'inline' }, enabled, 'Enabled')),
      h('div', { class: 'row end' }, h('button', { class: 'btn', type: 'submit' }, 'Add')),
    ),
    h(
      'table',
      {},
      h('thead', {}, h('tr', {}, ['Name', 'Value', 'Type', 'Enabled', ''].map((t) => h('th', {}, t)))),
      h(
        'tbody',
        {},
        rows.length
          ? rows.map((c) => {
              const n = h('input', { required: true, maxlength: 80, value: c.name, 'aria-label': 'Name' });
              const v = h('input', { required: true, type: 'number', min: 0, step: '0.01', value: c.value, 'aria-label': 'Value' });
              const t = typeSelect(c.type);
              const en = h('input', { type: 'checkbox', checked: c.enabled, 'aria-label': 'Enabled' });
              return h(
                'tr',
                {},
                h('td', {}, n),
                h('td', {}, v),
                h('td', {}, t),
                h('td', {}, en),
                h(
                  'td',
                  { class: 'row end' },
                  h(
                    'button',
                    {
                      class: 'btn sm',
                      onclick: () =>
                        guard(async () => {
                          await api('PUT', '/charges/' + c.id, payload(n, v, t, en));
                          toast('Saved');
                        }),
                    },
                    'Save',
                  ),
                  h(
                    'button',
                    {
                      class: 'btn danger sm',
                      onclick: () =>
                        guard(async () => {
                          if (!(await confirmBox('Delete charge "' + c.name + '"?'))) return;
                          await api('DELETE', '/charges/' + c.id);
                          await charges(main);
                        }),
                    },
                    'Delete',
                  ),
                ),
              );
            })
          : h('tr', {}, h('td', { colspan: 5 }, 'No charges yet')),
      ),
    ),
  );
}
