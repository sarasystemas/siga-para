import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import test from 'node:test';
import { Script } from 'node:vm';

const html = await readFile(new URL('../siga-para.html', import.meta.url), 'utf8');
const inlineScripts = [...html.matchAll(/<script\b[^>]*>([\s\S]*?)<\/script>/gi)]
  .map((match) => match[1])
  .filter((source) => source.trim());
const migration = await readFile(
  new URL('../supabase/migrations/20261017230000_tenant_schema.sql', import.meta.url),
  'utf8',
);

test('o JavaScript embutido pode ser analisado sem erro de sintaxe', () => {
  assert.ok(inlineScripts.length > 0);
  for (const source of inlineScripts) assert.doesNotThrow(() => new Script(source));
});

test('a interface identifica explicitamente o modo de demonstração', () => {
  assert.match(html, /Modo demonstração: login e permissões são simulados/);
  assert.match(html, /senhas e cadastros ficam sem criptografia neste navegador/);
  assert.match(html, /Não use dados reais/);
  assert.doesNotMatch(html, /Autenticação segura com JWT e senhas criptografadas/);
});

test('notificações tratam o texto como texto, não como HTML', () => {
  assert.match(html, /title\.textContent=titulo/);
  assert.match(html, /message\.textContent=corpo/);
});

test('o banco aplica RLS e limita os registros à equipe do município', () => {
  assert.match(migration, /enable row level security/i);
  assert.match(migration, /private\.is_tenant_member\(tenant_id\)/i);
  assert.match(migration, /auth\.uid\(\)/i);
});
