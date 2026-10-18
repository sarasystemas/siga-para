# SIGA Pará

Interface web do SIGA Pará, atualmente apresentada como **protótipo de demonstração**.

## Estado atual e limites

- A aplicação está em um único arquivo HTML e usa `localStorage` para persistir dados apenas no navegador atual.
- Login, senhas de demonstração, perfis e permissões são simulados no próprio código. As senhas de teste ficam em texto simples no armazenamento do navegador. Isso **não é autenticação**: um usuário pode inspecionar ou alterar o JavaScript e os dados locais.
- Os cadastros apresentados são fictícios. Não insira CPF, contatos, dados de agricultores ou qualquer outra informação pessoal ou real.
- A migração Supabase incluída é uma base de esquema e isolamento por município; o HTML **ainda não se conecta ao Supabase**. Não coloque o sistema em operação oficial nem trate a publicação da interface como implantação segura.
- O front-end atual ainda contém telas administrativas e indicadores ilustrativos; essas ações não provisionam contas, não enviam notificações e não executam backups de servidor.

## Executar localmente

Requer Node.js 20 ou superior. Não há dependências de runtime para instalar.

```sh
npm test
npm run build
```

O build copia `siga-para.html` para `dist/index.html`. Para uma prévia rápida, abra `siga-para.html` no navegador; o armazenamento da demonstração é local a esse navegador.

## GitHub

Crie um repositório privado se o código for destinado à operação interna. Revise o conteúdo antes do primeiro push e nunca adicione credenciais, chaves privadas, arquivos `.env` ou dados reais. O `.gitignore` exclui esses arquivos e o artefato `dist/`.

O workflow `.github/workflows/ci.yml` executa os testes e o build em cada push e pull request.

## Vercel

Importe o repositório no Vercel e configure:

- **Framework Preset:** Other
- **Build Command:** `npm run build`
- **Output Directory:** `dist`

Essas opções também estão declaradas em `vercel.json`. A configuração adiciona cabeçalhos básicos de segurança e uma Content Security Policy compatível com os recursos CDN usados pela página. Como a página ainda usa JavaScript e estilos inline, a política precisa permitir conteúdo inline; remover essa exceção depende de refatorar esses trechos.

## Supabase — preparação, ainda sem integração

A migração `supabase/migrations/20261017230000_tenant_schema.sql` cria tabelas relacionais para municípios, membros, agricultores, comunidades, técnicos, atendimentos e auditoria. As políticas RLS limitam cada equipe aos dados do próprio município. A equipe municipal compartilha os registros entre seus membros, conforme o modelo escolhido.

Para aplicar a migração, use o SQL Editor do projeto ou o Supabase CLI após inicializar e vincular o projeto (`supabase init`, `supabase link --project-ref <ref>` e `supabase db push`). Para iniciar um tenant, crie o usuário em **Authentication**, crie o município em `public.tenants` e associe o `auth.users.id` em `public.tenant_members` com o papel apropriado. A criação/convite de contas não é exposta a usuários anônimos.

**Antes de usar dados reais**, ainda é necessário integrar o Supabase Auth e substituir o acesso ao `localStorage` por operações no banco, mapear os dados da interface ao esquema, configurar recuperação de senha e validar a autorização no servidor. Hoje, as permissões de papel da interface são apenas visuais; as políticas incluídas permitem operações compartilhadas a qualquer membro do tenant e não substituem autorização por ação. Configure e teste regras de papel e auditoria imutável antes da operação oficial.

Se futuramente usar a chave `anon`/publishable do Supabase no navegador, ela é pública por definição e só é segura com RLS testada em todas as tabelas. **Nunca** inclua a chave `service_role` no HTML, em variáveis expostas ao cliente ou no GitHub.

## Privacidade e segurança

O SIGA pode vir a tratar CPF, localização, telefone e outros dados pessoais. Antes de produção, defina base legal, retenção, atendimento aos direitos dos titulares, controle de acesso, backup/restauração e resposta a incidentes com a equipe responsável pela LGPD. O aviso de demonstração na interface não substitui essas medidas.
