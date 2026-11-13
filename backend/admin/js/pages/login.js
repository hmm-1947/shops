import { h, field, toast } from '../ui.js';
import { api } from '../api.js';

export default function login(app) {
  const email = h('input', { type: 'email', required: true, autocomplete: 'username', maxlength: 254 });
  const password = h('input', { type: 'password', required: true, autocomplete: 'current-password', maxlength: 72 });
  const btn = h('button', { class: 'btn', type: 'submit' }, 'Sign in');
  app.replaceChildren(
    h(
      'form',
      {
        class: 'login',
        onsubmit: async (e) => {
          e.preventDefault();
          btn.disabled = true;
          try {
            await api('POST', '/auth/login', { email: email.value, password: password.value });
            location.hash = '#/products';
          } catch (err) {
            toast(err.message, true);
          } finally {
            btn.disabled = false;
          }
        },
      },
      h('h1', {}, 'WeMatch Admin'),
      field('Email', email),
      field('Password', password),
      btn,
    ),
  );
  email.focus();
}
